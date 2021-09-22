defmodule Warehouse.Sku do
  @moduledoc """
  This module handles high level functions for `Sku`s. It transparently handles
  the persistance layer with `Ecto` and the database, and the `GenServer`
  processes.
  """

  alias Warehouse.{AdditiveMap, Component, GenServers, Repo, Schemas}

  @supervisor Warehouse.SkuSupervisor
  @registry Warehouse.SkuRegistry

  @doc """
  Lists all SKUs we know about.

  ## Examples

      iex> list_skus()
      [%Schemas.Sku{}, %Schemas.Sku{}, %Schemas.Sku{}]

  """
  @spec list_skus() :: [Schemas.Sku.t()]
  def list_skus() do
    @supervisor
    |> DynamicSupervisor.which_children()
    |> Stream.map(fn {_, pid, _type, _modules} -> GenServer.call(pid, :get_info) end)
    |> Enum.into([])
  end

  @doc """
  Lists all SKUs that match the given list of IDs.

  ## Examples

      iex> list_skus([1, 2, 3])
      [%Schemas.Sku{}, %Schemas.Sku{}, %Schemas.Sku{}]

  """
  @spec list_skus([integer]) :: [Schemas.Sku.t()]
  def list_skus(filter) do
    filter
    |> Enum.map(&to_string/1)
    |> Enum.flat_map(&Registry.lookup(@registry, &1))
    |> Enum.map(fn {pid, _value} -> GenServer.call(pid, :get_info) end)
  end

  @doc """
  Starts a `Warehouse.GenServers.Sku` instance for everything in the database.
  This is used on application startup.
  """
  @spec warmup_skus() :: :ok
  def warmup_skus() do
    for sku <- Repo.all(Schemas.Sku) do
      DynamicSupervisor.start_child(@supervisor, {GenServers.Sku, sku})
    end

    :ok
  end

  @doc """
  Grabs information about a single SKU.

  ## Examples

      iex> get_sku(id)
      %Schemas.Sku{}

  """
  @spec get_sku(integer) :: Schemas.Sku.t()
  def get_sku(id) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.call(pid, :get_info)
      _ -> nil
    end
  end

  @doc """
  Grabs quantity information for a SKU.

  ## Examples

      iex> get_sku_quantity(id)
      %Schemas.Sku.quantity()

  """
  @spec get_sku_quantity(integer) :: Schemas.Sku.quantity()
  def get_sku_quantity(id) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.call(pid, :get_quantity)
      _ -> %{available: 0, demand: 0, excess: 0}
    end
  end

  @doc """
  Grabs the SKU demands from all known Components, and updates the SKU
  GenServers with new demand data.

  ## Examples

      iex> update_sku_demands()
      :ok

  """
  def update_sku_demands() do
    sku_demands = Component.get_sku_demands()

    @registry
    |> Registry.select([{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
    |> Enum.each(fn {id, pid} ->
      demand = AdditiveMap.get(sku_demands, id)
      GenServer.cast(pid, {:update_demand, demand})
    end)
  end
end
