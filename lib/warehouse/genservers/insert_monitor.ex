defmodule Warehouse.GenServers.InsertMonitor do
  @moduledoc """
  Monitors new SKUs and Components inserted in the database and starts their processes.
  """
  use GenServer

  import Ecto.Query

  alias Warehouse.Repo
  alias Warehouse.Schemas.Component
  alias Warehouse.Schemas.Sku

  require Logger

  @default_fetch_interval_ms :timer.seconds(60)

  @component_supervisor Warehouse.ComponentSupervisor
  @sku_supervisor Warehouse.SkuSupervisor

  defmodule State do
    @moduledoc false
    defstruct [
      :fetch_interval,
      :last_sku_id,
      :last_component_id
    ]

    @type t :: %__MODULE__{
            fetch_interval: non_neg_integer(),
            last_sku_id: non_neg_integer(),
            last_component_id: non_neg_integer()
          }
  end

  @spec start_link(keyword()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    name = opts[:name] || __MODULE__
    fetch_interval = opts[:fetch_interval] || @default_fetch_interval_ms
    GenServer.start_link(__MODULE__, %State{fetch_interval: fetch_interval}, name: name)
  end

  ## GenServer API

  @impl GenServer
  def init(state) do
    {:ok, state, {:continue, :warmup}}
  end

  @impl GenServer
  def handle_continue(:warmup, %State{fetch_interval: fetch_interval} = state) do
    {last_sku_id, last_component_id} = fetch(state)
    Logger.info("Components cache warmed up")
    schedule_next_fetch(fetch_interval)

    {:noreply, %State{state | last_sku_id: last_sku_id, last_component_id: last_component_id}}
  end

  @impl GenServer
  def handle_info(:fetch, %State{fetch_interval: fetch_interval} = state) do
    {last_sku_id, last_component_id} = fetch(state)
    schedule_next_fetch(fetch_interval)

    {:noreply, %State{state | last_sku_id: last_sku_id, last_component_id: last_component_id}}
  end

  defp schedule_next_fetch(fetch_interval) do
    Process.send_after(self(), :fetch, fetch_interval)
  end

  defp fetch(state) do
    last_sku_id = fetch_skus(state)
    last_component_id = fetch_components(state)

    {last_sku_id, last_component_id}
  end

  defp fetch_skus(state) do
    new_skus = get_new_skus(state)

    new_sku_count =
      Enum.reduce(new_skus, 0, fn sku, acc ->
        @sku_supervisor
        |> DynamicSupervisor.start_child({Warehouse.GenServers.Sku, sku})
        |> wrap_supervisor_start(acc)
      end)

    last_sku_id = new_skus |> List.last() |> id_or_nil()
    Logger.info("Spawned #{new_sku_count} new SKU processes", last_sku_id: last_sku_id)

    last_sku_id
  end

  defp fetch_components(state) do
    new_components = get_new_components(state)

    new_components_count =
      Enum.reduce(new_components, 0, fn component, acc ->
        @component_supervisor
        |> DynamicSupervisor.start_child({Warehouse.GenServers.Component, [component: component]})
        |> wrap_supervisor_start(acc)
      end)

    last_component_id = new_components |> List.last() |> id_or_nil()

    Logger.info("Spawned #{new_components_count} new component processes",
      last_component_id: last_component_id
    )

    if new_components_count > 0 do
      Task.Supervisor.async_nolink(Warehouse.TaskSupervisor, &update_demands/0)
    end

    last_component_id
  end

  defp get_new_skus(%State{last_sku_id: nil}) do
    Repo.all(Sku)
  end

  defp get_new_skus(%State{last_sku_id: last_sku_id}) do
    Sku
    |> where([s], s.id > ^last_sku_id)
    |> Repo.all()
  end

  defp get_new_components(%State{last_component_id: nil}) do
    Repo.all(Component)
  end

  defp get_new_components(%State{last_component_id: last_component_id}) do
    Component
    |> where([c], c.id > ^last_component_id)
    |> Repo.all()
  end

  defp update_demands() do
    Warehouse.AssemblyService.request_component_demands()
    |> Stream.map(fn %{component_id: id, demand_quantity: demand} -> [id, demand] end)
    |> Stream.each(&apply(Warehouse.Component, :update_component_demand, &1))
    |> Stream.run()
  end

  defp wrap_supervisor_start({:ok, _child}, acc), do: acc + 1
  defp wrap_supervisor_start({:ok, _child, _info}, acc), do: acc + 1
  defp wrap_supervisor_start(_, acc), do: acc

  defp id_or_nil(nil), do: nil
  defp id_or_nil(struct), do: struct.id
end
