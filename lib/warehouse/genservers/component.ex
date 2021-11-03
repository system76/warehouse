defmodule Warehouse.GenServers.Component do
  @moduledoc """
  A GenServer instance that runs for every `Warehouse.Schemas.Component` to keep
  track of assembly demand, kitting instructions, and where available parts to
  pick are located.
  """

  use GenServer, restart: :transient

  require Logger

  alias Warehouse.{Kit, Schemas, Sku}

  # Check for new kit updates every minute.
  @update_interval_ms :timer.seconds(60)

  def start_link(opts) do
    component = opts[:component]
    update_interval = opts[:update_interval] || @update_interval_ms

    GenServer.start_link(
      __MODULE__,
      %{component: component, update_interval: update_interval},
      name: name(component)
    )
  end

  defp name(%Schemas.Component{id: id}), do: name(id)
  defp name(id), do: {:via, Registry, {Warehouse.ComponentRegistry, to_string(id)}}

  @impl true
  def init(%{component: %Schemas.Component{} = component, update_interval: update_interval}) do
    Logger.metadata(component_id: component.id)

    kits = Kit.get_component_kits(component.id)
    schedule_next_update(update_interval)

    {:ok,
     %{
       update_interval: update_interval,
       available: 0,
       component: component,
       demand: 0,
       kits: kits,
       sku_demands: %{}
     }}
  end

  def update_interval do
    @update_interval_ms
  end

  @impl true
  def handle_call(:get_available, _from, state) do
    {:reply, state.available, state}
  end

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, state.component, state}
  end

  @impl true
  def handle_call(:get_picking_options, _from, state) do
    options = Enum.map(state.kits, &Kit.get_kit_picking_options/1)
    {:reply, options, state}
  end

  @impl true
  def handle_call(:get_sku_demands, _from, state) do
    {:reply, state.sku_demands, state}
  end

  @impl true
  def handle_cast({:set_demand, demand}, state) do
    Logger.info("Updating demand quantity to #{demand}")
    sku_demands = Kit.kit_sku_demand(state.kits, demand)

    Task.Supervisor.async_nolink(Warehouse.TaskSupervisor, Sku, :update_sku_demands, [])
    {:noreply, %{state | demand: demand, sku_demands: sku_demands}}
  end

  @impl true
  def handle_cast({:set_kits, kits}, state) do
    Process.send_after(self(), :update_available, 0)
    {:noreply, %{state | kits: kits}}
  end

  @impl true
  def handle_info(:update_kits, %{component: component, kits: kits, update_interval: update_interval} = state) do
    new_kits = Kit.get_component_kits(component.id)

    schedule_next_update(update_interval)

    if Enum.sort(new_kits) == Enum.sort(kits) do
      {:noreply, state}
    else
      Process.send_after(self(), :update_available, 1)
      {:noreply, %{state | kits: new_kits}}
    end
  end

  def handle_info(:update_available, state) do
    new_available = Kit.get_kit_availability(state.kits)

    if new_available != state.available do
      Logger.info("Updating available quantity to #{new_available}")
      new_state = %{state | available: new_available}
      events_module().broadcast_component_quantities(state.component.id, new_state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({_ref, :ok}, state), do: {:noreply, state}

  @impl true
  def handle_info({_ref, res}, state) do
    Logger.warn("Error while updating sku demands", resource: inspect(res))
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state), do: {:noreply, state}

  defp events_module(), do: Application.get_env(:warehouse, :events)

  defp schedule_next_update(update_interval) do
    Process.send_after(self(), :update_kits, update_interval)
  end
end
