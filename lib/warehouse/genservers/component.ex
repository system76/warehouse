defmodule Warehouse.GenServers.Component do
  @moduledoc """
  A GenServer instance that runs for every `Warehouse.Schemas.Component` to keep
  track of assembly demand, kitting instructions, and where available parts to
  pick are located.
  """

  use GenServer, restart: :transient

  require Logger

  alias Warehouse.Clients.Assembly
  alias Warehouse.Component
  alias Warehouse.Kit
  alias Warehouse.Schemas
  alias Warehouse.Sku

  def start_link(opts) do
    component = opts[:component]

    GenServer.start_link(__MODULE__, %{component: component}, name: name(component))
  end

  defp name(%Schemas.Component{id: id}), do: name(id)
  defp name(id), do: {:via, Registry, {Warehouse.ComponentRegistry, to_string(id)}}

  @impl true
  def init(%{component: %Schemas.Component{} = component}) do
    Logger.metadata(component_id: component.id)

    kits = Kit.get_component_kits(component.id)

    {:ok,
     %{
       available: 0,
       component: component,
       demand: 0,
       kits: kits,
       sku_demands: %{}
     }}
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
    Task.Supervisor.async_nolink(Warehouse.TaskSupervisor, fn ->
      update_demands(state.component.id)
    end)

    Process.send_after(self(), :update_available, 0)
    {:noreply, %{state | kits: kits}}
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

  defp update_demands(component_id) do
    Assembly.request_component_demands()
    |> Stream.filter(fn %{component_id: id} -> to_string(id) == to_string(component_id) end)
    |> Stream.each(fn %{component_id: id, demand_quantity: demand} ->
      Component.update_component_demand(id, demand)
    end)
    |> Stream.run()
  end
end
