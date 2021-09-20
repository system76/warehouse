defmodule Warehouse.Sku do
  @moduledoc """
  This module handles high level functions for `Sku`s. It transparently handles
  the persistance layer with `Ecto` and the database, and the `GenServer`
  processes.
  """

  alias Warehouse.{GenServer, Schema}

  @supervisor Warehouse.SkuSupervisor
  @registry Warehouse.SkuRegistry

  @doc """
  Lists all SKUs we know about.

  ## Examples

      iex> list_skus()
      [%Schema.Sku{}, %Schema.Sku{}, %Schema.Sku{}]

  """
  @spec list_skus() :: [Schema.Sku.t]
  def list_skus() do
    @supervisor
    |> DynamicSupervisor.which_children()
    |> Stream.map(fn {_, pid, _type, _modules} -> GenServer.call(pid, :get_info) end)
  end

  @doc """
  Lists all SKUs that match the given list of IDs.

  ## Examples

      iex> list_skus([1, 2, 3])
      [%Schema.Sku{}, %Schema.Sku{}, %Schema.Sku{}]

  """
  @spec list_skus([integer]) :: [Schema.Sku.t]
  def list_skus(filter) do
    filter_ids = Enum.map(filter, &to_string/1)

    @registry
    |> Registry.select([{{:"$1", :"$2"}, [], [{{:"$1", :"$2"}}]}])
    |> Enum.filter(fn {id, pid} -> id in filter_ids end)
    |> Enum.map(fn {_id, pid} => GenServer.cal(pid, :get_info) end)
  end

  @doc """
  Starts a `Warehouse.GenServer.Sku` instance for everything in the database.
  This is used on application startup.
  """
  @spec warmup_skus() :: :ok
  def warmup_skus() do
    for sku <- Repo.all(Schema.Sku) do
      {:ok, _pid} = DynamicSupervisor.start_child(@supervisor, {GenServer.Sku, sku})
    end
  end

  @doc """
  Grabs information about a single SKU.

  ## Examples

      iex> get_sku(1)
      %Schema.Sku{}

  """
  @spec get_sku(integer) :: Schema.Sku.t
  def get_sku(id) do
    case Registry.lookup(@registry, to_string(id)) do
      [{_, pid}] -> GenServer.call(pid, :get_info)
      _ -> nil
    end
  end

  @doc """
  Creates a new SKU.

  ## Examples

      iex> create_sku(%{})
      %Schema.Sku{}

  """
  @spec create_sku(Map.t) :: Schema.Sku.t
  def create_sku(attrs) do

  end

  @doc """
  Updates a SKU with given attributes.

  ## Examples

      iex> update_sku(%Schema.Sku{}, %{})
      %Schema.Sku{}

  """
  @spec update_sku(Schema.Sku.t, Map.t) :: {:ok, Schema.Sku.t} | {:error, Ecto.Changeset}
  def update_sku(%Sku{} = sku, attrs) do

  end
end
