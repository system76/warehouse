defmodule Warehouse.GenServer.Sku do
  @moduledoc """
  A GenServer instance that runs for every `Warehouse.Schema.Sku` to keep track
  of live data, like the total quantity of parts that are available to pick,
  and the total quantity that is demanded by builds.
  """

  use GenServer

  @registry Warehoues.SkuRegistry

  @impl true
  def start_child(%Schema.Sku{} = sku) do
    GenServer.start_child(__MODULE__, sku, name: name(sku))
  end

  defp name(%Schema.Sku{id: id}), do: name(id)
  defp name(id), do: {:via, @registry, {__MODULE__, to_string(id)}}

  @impl true
  def init(%Schema.Sku{} = sku) do
    Logger.metadata(sku_id: sku.id)

    Process.send_after(self(), :update_available_quantity, timeout())
    {:ok, %{sku: sku}}
  end

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, state.sku, state}
  end

  @impl true
  def handle_info(:update_available_quantity, state) do
    database_sku =
      Schema.Sku
      |> where(id: state.sku.id)
      |> Schema.Sku.populate_available_quantity()
      |> Repo.one()

    updated_sku = Map.put(database_sku, :current_demand, state.sku.current_demand)

    Logger.info("Updating available quantity to #{updated_sku.available_quantity}")
    Process.send_after(self(), :update_available_quantity, timeout())
    {:noreply, %{sku: updated_sku}}
  end

  defp timeout(), do: 4 * 60 * 60 * 1000 + Enum.random(60000..600000)
end
