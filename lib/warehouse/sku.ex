defmodule Warehouse.Sku do
  @moduledoc """
  This module handles high level functions for `Sku`s. It transparently handles
  the persistance layer with `Ecto` and the database, and the `GenServer`
  processes.
  """

  alias Warehouse.{GenServers, Repo, Schemas}

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
      {:ok, _pid} = DynamicSupervisor.start_child(@supervisor, {GenServers.Sku, sku})
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
end
