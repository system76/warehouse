use Mix.Config

config :warehouse,
  producer: {Broadway.DummyProducer, []}

config :warehouse, Warehouse.Repo,
  username: "root",
  password: "system76",
  database: "hal_test",
  hostname: Map.get(System.get_env(), "DB_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox
