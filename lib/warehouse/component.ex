defmodule Warehouse.Component do
  @moduledoc """
  This module handles high level functions for `Warehouse.Schemas.Component`s.
  It transparently handles the persistance layer with `Ecto` and the database,
  and the `GenServer` processes.
  """

  alias Warehouse.AdditiveMap
  alias Warehouse.GenServers.Component, as: ComponentServer
  alias Warehouse.Kit
  alias Warehouse.Schemas
  alias Warehouse.Repo

  @supervisor Warehouse.ComponentSupervisor
  @registry Warehouse.ComponentRegistry

  @timeout_genserver 120_000

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
    |> Stream.map(fn {_, pid, _type, _modules} -> GenServer.call(pid, :get_info, @timeout_genserver) end)
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
    |> Enum.map(fn {pid, _value} -> GenServer.call(pid, :get_info, @timeout_genserver) end)
  end

  @doc """
  Starts a `Warehouse.GenServers.Component` instance for everything in the database.
  This is used on application startup.
  """
  @spec warmup_components() :: :ok
  def warmup_components do
    for component <- Repo.all(Schemas.Component) do
      {:ok, _} = DynamicSupervisor.start_child(@supervisor, {ComponentServer, [component: component]})
    end

    :ok
  end

  @doc """
  Grabs information about a single component.

  ## Examples

      iex> get_component(id)
      %Schemas.Component{}

  """
  @spec get_component(integer) :: Schemas.Component.t() | nil
  def get_component(id) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.call(pid, :get_info, @timeout_genserver)
      _ -> nil
    end
  end

  @doc """
  Gets the quantity available for a given component id. Will return 0 if we have
  no information about the component, or the ID given is invalid.

  ## Examples

      iex> get_component_availability(id)
      3

  """
  @spec get_component_availability(integer) :: non_neg_integer()
  def get_component_availability(id) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.call(pid, :get_available, @timeout_genserver)
      _ -> 0
    end
  end

  @doc """
  Returns a list of picking options for a component. Note that this can return
  options that do not have enough quantity to be picked.

  ## Examples

      iex> get_component_picking_options(id)
      []

  """
  @spec get_component_picking_options(integer) :: [Kit.picking_option()]
  def get_component_picking_options(id) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.call(pid, :get_picking_options, @timeout_genserver)
      _ -> []
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
    |> Stream.map(fn {_, pid, _type, _modules} -> GenServer.call(pid, :get_sku_demands, @timeout_genserver) end)
    |> Enum.into([])
    |> Enum.reduce(%{}, &AdditiveMap.merge/2)
  end

  @doc """
  Iterates over all components, and evaluates the availability based on the kits
  they have and sku availability numbers.

  ## Examples

      iex> update_component_availability()
      :ok

  """
  @spec update_component_availability() :: :ok
  def update_component_availability() do
    @supervisor
    |> DynamicSupervisor.which_children()
    |> Stream.map(fn {_, pid, _type, _modules} -> send(pid, :update_available) end)
    |> Stream.run()
  end

  @doc """
  Sets the demand on a component.

  ## Examples

      iex> update_component_demand(id, 5)
      :ok

  """
  @spec update_component_demand(integer(), integer()) :: :ok | :error
  def update_component_demand(id, demand) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.cast(pid, {:set_demand, demand})
      _ -> :error
    end
  end

  @doc """
  Updates the component's kit data.

  ## Examples

      iex> update_component_kits(id, [%Warehouse.Schemas.Kit{}])
      :ok

  """
  @spec update_component_kits(integer) :: :ok | :error
  def update_component_kits(id) do
    new_kits = Kit.get_component_kits(to_string(id))
    update_component_kits(id, new_kits)
  end

  @spec update_component_kits(integer, [Schemas.Kit.t()]) :: :ok | :error
  def update_component_kits(id, kits) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.cast(pid, {:set_kits, kits})
      _ -> :error
    end
  end
end
