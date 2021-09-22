import Config

config :logger,
  backends: [LoggerJSON],
  level: :info

config :warehouse, Warehouse.Tracer, disabled?: false
