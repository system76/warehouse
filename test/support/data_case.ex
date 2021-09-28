defmodule Warehouse.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto.Query
      import Mox, only: [set_mox_from_context: 1]
      import Warehouse.DataCase
      import Warehouse.Factory

      alias Ecto.Changeset
      alias Warehouse.Repo

      @moduletag capture_log: true

      setup :set_mox_from_context
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Warehouse.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Warehouse.Repo, {:shared, self()})
    end

    on_exit(fn ->
      Warehouse.ComponentSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.map(fn {_, pid, _, _} -> pid end)
      |> Enum.map(fn pid -> DynamicSupervisor.terminate_child(Warehouse.ComponentSupervisor, pid) end)

      Warehouse.SkuSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.map(fn {_, pid, _, _} -> pid end)
      |> Enum.map(fn pid -> DynamicSupervisor.terminate_child(Warehouse.SkuSupervisor, pid) end)
    end)

    :ok
  end
end
