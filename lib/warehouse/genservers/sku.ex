defmodule Warehouse.GenServers.Sku do
  @moduledoc """
  A GenServer instance that runs for every `Warehouse.Schemas.Sku` to keep track
  of live data, like the total quantity of parts that are available to pick,
  and the total quantity that is demanded by builds.
  """

  use GenServer, restart: :transient

  require Logger

  alias Warehouse.{Component, Part, Schemas}

  def start_link(%Schemas.Sku{} = sku) do
    GenServer.start_link(__MODULE__, sku, name: name(sku))
  end

  defp name(%Schemas.Sku{id: id}), do: name(id)
  defp name(id), do: {:via, Registry, {Warehouse.SkuRegistry, to_string(id)}}

  @impl true
  def init(%Schemas.Sku{} = sku) do
    Logger.metadata(sku_id: sku.id)

    Process.send_after(self(), :update_available, Enum.random(0..60_000))

    {:ok,
     %{
       available: 0,
       demand: 0,
       excess: 0,
       pickable_locations: [],
       sku: sku
     }}
  end

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, state.sku, state}
  end

  @impl true
  def handle_call(:get_quantity, _from, state) do
    {:reply, Map.take(state, [:available, :demand, :excess]), state}
  end

  @impl true
  def handle_call(:get_pickable_locations, _from, state) do
    {:reply, state.pickable_locations, state}
  end

  @impl true
  def handle_cast({:update_demand, demand}, %{demand: current_demand} = state) do
    new_excess = max(state.available - demand, 0)

    if demand != current_demand or new_excess != state.excess do
      Logger.info("Updating demand quantity to #{demand} with #{new_excess} excess")
      new_state = %{state | demand: demand, excess: new_excess}
      events_module().broadcast_sku_quantities(state.sku.id, new_state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:update_available, %{sku: %{id: sku_id}} = state) do
    new_pickable_locations = Part.get_pickable_locations_for_sku(sku_id)
    new_available = new_pickable_locations |> Enum.map(&Map.get(&1, :quantity)) |> Enum.sum()
    new_excess = max(new_available - state.demand, 0)

    Process.send_after(self(), :update_available, Enum.random(3_600_000..7_200_000))

    if new_available != state.available or new_excess != state.excess do
      Logger.info("Updating available quantity to #{new_available} with #{new_excess} excess")
      new_state = %{state | available: new_available, excess: new_excess, pickable_locations: new_pickable_locations}
      events_module().broadcast_sku_quantities(sku_id, new_state)
      Task.Supervisor.async_nolink(Warehouse.TaskSupervisor, Component, :update_component_availability, [])
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({_ref, :ok}, state), do: {:noreply, state}

  @impl true
  def handle_info({_ref, res}, state) do
    Logger.warn("Error while updating component availability", resource: inspect(res))
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state), do: {:noreply, state}

  defp events_module(), do: Application.get_env(:warehouse, :events)
end
