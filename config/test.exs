import Config

config :warehouse,
  events: Warehouse.MockEvents,
  producer: {Broadway.DummyProducer, []}

config :warehouse, Warehouse.Repo,
  username: "root",
  password: "warehouse",
  database: "warehouse_test",
  hostname: Map.get(System.get_env(), "DB_HOST", "localhost"),
  port: System.get_env() |> Map.get("DB_PORT", "3306") |> String.to_integer(),
  pool: Ecto.Adapters.SQL.Sandbox

config :warehouse, Warehouse.Clients.Assembly, implementation: Warehouse.Clients.Assembly.Mock
