defmodule Warehouse.Sku do
  @moduledoc """
  This module handles high level functions for `Sku`s. It transparently handles
  the persistance layer with `Ecto` and the database, and the `GenServer`
  processes.
  """

  alias Warehouse.AdditiveMap
  alias Warehouse.Component
  alias Warehouse.GenServers.Sku, as: SkuServer
  alias Warehouse.Schemas
  alias Warehouse.Repo

  require Logger

  @supervisor Warehouse.SkuSupervisor
  @registry Warehouse.SkuRegistry

  @type id :: integer() | String.t()

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
  @spec list_skus([id()]) :: [Schemas.Sku.t()]
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
  def warmup_skus do
    for sku <- Repo.all(Schemas.Sku) do
      DynamicSupervisor.start_child(@supervisor, {SkuServer, sku})
    end

    :ok
  end

  @doc """
  Grabs information about a single SKU.

  ## Examples

      iex> get_sku(id)
      %Schemas.Sku{}

  """
  @spec get_sku(id()) :: Schemas.Sku.t() | nil
  def get_sku(id) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.call(pid, :get_info)
      _ ->
        Logger.debug("sku genserver not started for id: #{inspect(id)}")
        nil
    end
  end

  @doc """
  Returns a list of locations with pickable parts for a SKU. If the sku is
  unknown, we return an empty list.

  ## Examples

      iex> get_sku_pickable_locations(id)
      []

  """
  @spec get_sku_pickable_locations(id()) :: [Schemas.Location.quantity()]
  def get_sku_pickable_locations(id) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.call(pid, :get_pickable_locations)
      _ -> []
    end
  end

  @doc """
  Grabs quantity information for a SKU.

  ## Examples

      iex> get_sku_quantity(id)
      %Schemas.Sku.quantity()

  """
  @spec get_sku_quantity(id()) :: Schemas.Sku.quantity()
  def get_sku_quantity(id) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.call(pid, :get_quantity)
      _ -> %{available: 0, demand: 0, excess: 0}
    end
  end

  @doc """
  Updates the sku availability by querying the database for all pickable parts.
  Will emit appropriate events if any amount changes.

  ## Examples

      iex> update_sku_availability(id)
      :ok

  """
  @spec update_sku_availability(id()) :: :ok
  def update_sku_availability(id) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> send(pid, :update_available)
      _ -> :ok
    end
  end

  @doc """
  Grabs the SKU demands from all known Components, and updates the SKU
  GenServers with new demand data.

  ## Examples

      iex> update_sku_demands()
      :ok

  """
  @spec update_sku_demands() :: :ok
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
