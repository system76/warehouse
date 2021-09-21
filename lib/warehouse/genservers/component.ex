defmodule Warehouse.GenServers.Component do
  @moduledoc """
  A GenServer instance that runs for every `Warehouse.Schemas.Component` to keep
  track of assembly demand, kitting instructions, and where available parts to
  pick are located.
  """

  use GenServer, restart: :transient

  import Ecto.Query

  require Logger

  alias Warehouse.{Repo, Schemas}

  def start_link(%Schemas.Component{} = component) do
    GenServer.start_link(__MODULE__, component, name: name(component))
  end

  defp name(%Schemas.Component{id: id}), do: name(id)
  defp name(id), do: {:via, Registry, {Warehouse.ComponentRegistry, to_string(id)}}

  @impl true
  def init(%Schemas.Component{} = component) do
    Logger.metadata(component_id: component.id)
    {:ok, %{available: 0, component: component, demand: 0}}
  end

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, state.component, state}
  end
end
