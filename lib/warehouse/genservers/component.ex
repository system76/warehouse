defmodule Warehouse.GenServers.Component do
  @moduledoc """
  A GenServer instance that runs for every `Warehouse.Schemas.Component` to keep
  track of assembly demand, kitting instructions, and where available parts to
  pick are located.
  """

  use GenServer, restart: :transient

  require Logger

  alias Warehouse.{Kit, Schemas, Sku}

  def start_link(%Schemas.Component{} = component) do
    GenServer.start_link(__MODULE__, component, name: name(component))
  end

  defp name(%Schemas.Component{id: id}), do: name(id)
  defp name(id), do: {:via, Registry, {Warehouse.ComponentRegistry, to_string(id)}}

  @impl true
  def init(%Schemas.Component{} = component) do
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
  def handle_call(:get_sku_demands, _from, state) do
    {:reply, state.sku_demands, state}
  end

  @impl true
  def handle_cast({:set_demand, demand}, state) do
    sku_demands = Kit.kit_sku_demand(state.kits, demand)

    Task.Supervisor.async_nolink(Warehouse.TaskSupervisor, Sku, :update_sku_demands, [])
    {:noreply, %{state | demand: demand, sku_demands: sku_demands}}
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
end
