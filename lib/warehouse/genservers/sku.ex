defmodule Warehouse.GenServers.Sku do
  @moduledoc """
  A GenServer instance that runs for every `Warehouse.Schemas.Sku` to keep track
  of live data, like the total quantity of parts that are available to pick,
  and the total quantity that is demanded by builds.
  """

  use GenServer, restart: :transient

  import Ecto.Query

  require Logger

  alias Warehouse.{Repo, Schemas}

  def start_link(%Schemas.Sku{} = sku) do
    GenServer.start_link(__MODULE__, sku, name: name(sku))
  end

  defp name(%Schemas.Sku{id: id}), do: name(id)
  defp name(id), do: {:via, Registry, {Warehouse.SkuRegistry, to_string(id)}}

  @impl true
  def init(%Schemas.Sku{} = sku) do
    Logger.metadata(sku_id: sku.id)

    Process.send_after(self(), :update_available_quantity, timeout())
    {:ok, %{sku: sku}}
  end

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, state.sku, state}
  end

  @impl true
  def handle_info(:update_available_quantity, %{sku: %{id: sku_id}} = state) do
    query =
      Schemas.Sku
      |> where([s], s.id == ^sku_id)
      |> Schemas.Sku.populate_available_quantity()

    if database_sku = Repo.one(query) do
      updated_sku = Map.put(database_sku, :current_demand, state.sku.current_demand)

      Logger.info("Updating available quantity to #{updated_sku.available_quantity}")
      Process.send_after(self(), :update_available_quantity, timeout())
      {:noreply, %{sku: updated_sku}}
    else
      # This can happen if some external service deletes the SKU (mostly tests)
      {:noreply, state}
    end
  end

  defp timeout(), do: 4 * 60 * 60 * 1000 + Enum.random(60_000..600_000)
end
