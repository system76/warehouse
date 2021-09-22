defmodule Warehouse.Component do
  @moduledoc """
  This module handles high level functions for `Warehouse.Schemas.Component`s.
  It transparently handles the persistance layer with `Ecto` and the database,
  and the `GenServer` processes.
  """

  alias Warehouse.{AdditiveMap, GenServers, Repo, Schemas}

  @supervisor Warehouse.ComponentSupervisor
  @registry Warehouse.ComponentRegistry

  @doc """
  Lists all components we know about.

  ## Examples

      iex> list_components()
      [%Schemas.Component{}, %Schemas.Component{}, %Schemas.Component{}]

  """
  @spec list_components() :: [Schemas.Component.t()]
  def list_components() do
    @supervisor
    |> DynamicSupervisor.which_children()
    |> Stream.map(fn {_, pid, _type, _modules} -> GenServer.call(pid, :get_info) end)
    |> Enum.into([])
  end

  @doc """
  Lists all components that match the given list of IDs.

  ## Examples

      iex> list_components([1, 2, 3])
      [%Schemas.Component{}, %Schemas.Component{}, %Schemas.Component{}]

  """
  @spec list_components([integer]) :: [Schemas.Component.t()]
  def list_components(filter) do
    filter
    |> Enum.map(&to_string/1)
    |> Enum.flat_map(&Registry.lookup(@registry, &1))
    |> Enum.map(fn {pid, _value} -> GenServer.call(pid, :get_info) end)
  end

  @doc """
  Starts a `Warehouse.GenServers.Component` instance for everything in the database.
  This is used on application startup.
  """
  @spec warmup_components() :: :ok
  def warmup_components() do
    for component <- Repo.all(Schemas.Component) do
      DynamicSupervisor.start_child(@supervisor, {GenServers.Component, component})
    end

    :ok
  end

  @doc """
  Grabs information about a single component.

  ## Examples

      iex> get_component(id)
      %Schemas.Component{}

  """
  @spec get_component(integer) :: Schemas.Component.t()
  def get_component(id) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.call(pid, :get_info)
      _ -> nil
    end
  end

  @doc """
  Iterates over all components, fetches the demand of the kit skus, and merges
  them together.

  ## Examples

      iex> get_sku_demands()
      %{"A" => 4, "B" => 2, "C" => 0}

  """
  @spec get_sku_demands() :: AdditiveMap.t()
  def get_sku_demands() do
    @supervisor
    |> DynamicSupervisor.which_children()
    |> Stream.map(fn {_, pid, _type, _modules} -> GenServer.call(pid, :get_sku_demands) end)
    |> Enum.into([])
    |> Enum.reduce(%{}, &AdditiveMap.merge/2)
  end

  @doc """
  Sets the demand on a component.

  ## Examples

      iex> update_component_demand(id, 5)
      :ok

  """
  def update_component_demand(id, demand) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.cast(pid, {:set_demand, demand})
      _ -> :error
    end
  end
end
