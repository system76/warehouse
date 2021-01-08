import Config

config :warehouse, Warehouse.Repo,
  username: "root",
  password: "warehouse",
  database: "warehouse",
  hostname: "localhost",
  pool_size: 10
