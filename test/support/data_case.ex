defmodule Warehouse.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Warehouse.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Warehouse.DataCase

      import Warehouse.Factory
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Warehouse.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Warehouse.Repo, {:shared, self()})
    end

    :ok
  end
end
