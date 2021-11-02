defmodule Warehouse.GenServers.Cache do
  @moduledoc """
  Generic caching for components and SKU to avoid expensive DB requests.
  """
  use GenServer

  alias Warehouse.Repo
  alias Warehouse.Schemas.Component

  require Logger

  @default_warmup_interval 60_000

  @spec start_link(keyword()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    name = opts[:name] || __MODULE__
    warmup_interval = opts[:warmup_interval] || @default_warmup_interval
    table_name = opts[:table_name]
    GenServer.start_link(__MODULE__, %{warmup_interval: warmup_interval, table_name: table_name}, name: name)
  end

  def get(server \\ __MODULE__, key) do
    GenServer.call(server, {:get, key})
  end

  def put(server \\ __MODULE__, key, data) do
    GenServer.cast(server, {:put, key, data})
  end

  ## GenServer API

  @impl GenServer
  def init(%{table_name: table_name} = state) do
    Logger.info("Initializing cache #{table_name}")

    :ets.new(table_name, [:set, :protected, :named_table])

    {:ok, state, {:continue, :warmup}}
  end

  @impl GenServer
  def handle_continue(:warmup, %{table_name: table_name} = state) do
    Component
    |> Repo.all()
    |> Enum.each(fn component ->
      true = :ets.insert(table_name, {component.id, component})
    end)

    Logger.info("Cache warmed up for #{table_name}")

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, %{table_name: table_name} = state) do
    reply =
      case :ets.lookup(table_name, key) do
        [] -> nil
        [_key, component_state] -> component_state
      end

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_cast({:put, key, data}, %{table_name: table_name} = state) do
    :ets.insert(table_name, {key, data})

    {:noreply, state}
  end
end
