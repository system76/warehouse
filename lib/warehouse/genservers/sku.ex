defmodule Warehouse.GenServers.Sku do
  @moduledoc """
  A GenServer instance that runs for every `Warehouse.Schemas.Sku` to keep track
  of live data, like the total quantity of parts that are available to pick,
  and the total quantity that is demanded by builds.
  """

  use GenServer, restart: :transient

  require Logger

  alias Warehouse.{Part, Schemas}

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
  def handle_cast({:update_demand, demand}, %{demand: current_demand} = state) do
    if demand != current_demand do
      Logger.debug("Updating demand quantity to #{demand}")
      Process.send_after(self(), :update_excess, 0)
      {:noreply, %{state | demand: demand}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:update_available, %{sku: %{id: sku_id}} = state) do
    new_available = Part.get_pickable_quantity_for_sku(sku_id)

    if new_available != state.available do
      Logger.debug("Updating available quantity to #{new_available}")
      Process.send_after(self(), :update_excess, 0)
      Process.send_after(self(), :update_available, timeout())
      {:noreply, %{state | available: new_available}}
    else
      Process.send_after(self(), :update_available, timeout())
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:update_excess, %{available: available, demand: demand} = state) do
    new_excess = max(available - demand, 0)

    if new_excess != state.excess do
      Logger.debug("We now have #{new_excess} parts up for grabs")
      {:noreply, %{state | excess: new_excess}}
    else
      {:noreply, state}
    end
  end

  defp timeout(), do: 4 * 60 * 60 * 1000 + Enum.random(60_000..600_000)
end
