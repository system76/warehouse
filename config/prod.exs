import Config

config :logger, backends: [LoggerJSON]

config :warehouse, Warehouse.Tracer, disabled?: false
