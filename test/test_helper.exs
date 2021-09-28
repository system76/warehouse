Mox.defmock(Warehouse.MockEvents, for: Warehouse.Events)

Application.ensure_all_started(:ex_machina)

Ecto.Adapters.SQL.Sandbox.mode(Warehouse.Repo, :manual)

ExUnit.start()
