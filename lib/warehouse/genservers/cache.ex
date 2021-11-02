defmodule Warehouse.GenServers.Cache do
  @moduledoc """
  Generic caching for components and SKU to avoid expensive DB requests.
  """
  use GenServer

  alias Warehouse.Repo
  alias Warehouse.Schemas.Component

  require Logger

  @spec start_link(atom()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(name) when is_atom(name) do
    GenServer.start_link(__MODULE__, [name])
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, data) do
    GenServer.cast(__MODULE__, {:put, key, data})
  end

  ## GenServer API

  @impl GenServer
  def init([name] = state) do
    Logger.info("Initializing cache #{name}")

    :ets.new(name, [:set, :protected, :named_table])

    {:ok, state, {:continue, :warmup}}
  end

  @impl GenServer
  def handle_continue(:warmup, [name] = state) do

    Component
    |> Repo.all()
    |> Enum.each(fn component ->
      true = :ets.insert(name, {component.id, component})
    end)

    Logger.info("Cache warmed up for #{name}")

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, [name] = state) do
    reply =
      case :ets.lookup(name, key) do
        [] -> nil
        [_key, component_state] -> component_state
      end

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_cast({:put, key, data}, [name] = state) do
    :ets.insert(name, {key, data})

    {:noreply, state}
  end
end
