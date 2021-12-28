Mox.defmock(Warehouse.MockEvents, for: Warehouse.Events)
Mox.defmock(Warehouse.Clients.Assembly.Mock, for: Warehouse.Clients.Assembly)

Application.ensure_all_started(:ex_machina)

Ecto.Adapters.SQL.Sandbox.mode(Warehouse.Repo, :manual)

ExUnit.start()
