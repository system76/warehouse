use Mix.Config

config :warehouse, Warehouse.Repo,
  username: "root",
  password: "system76",
  database: "joshua",
  hostname: "localhost",
  pool_size: 10
