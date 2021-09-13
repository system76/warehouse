import Config

config :warehouse,
  env: Mix.env(),
  ecto_repos: [Warehouse.Repo]

config :warehouse,
  producer: {BroadwayRabbitMQ.Producer, queue: "", connection: []},
  exluded_picking_locations: [
    # shipping
    208,
    # transit-1
    237,
    # shipped
    242,
    # lab
    243,
    # unknown
    265,
    # R&D 1
    399,
    # rma
    400,
    # sarah's desk
    401
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :part_id, :build_id, :trace_id, :span_id, :resource],
  level: :info

config :logger_json, :backend,
  formatter: LoggerJSON.Formatters.DatadogLogger,
  metadata: :all

config :grpc, start_server: true

config :ex_aws,
  access_key_id: nil,
  secret_access_key: nil,
  region: nil

config :warehouse, Warehouse.Tracer,
  service: :warehouse,
  adapter: SpandexDatadog.Adapter,
  disabled?: true

config :warehouse, SpandexDatadog.ApiServer,
  batch_size: 2,
  http: HTTPoison,
  host: "127.0.0.1"

config :spandex, :decorators, tracer: Warehouse.Tracer

import_config "#{Mix.env()}.exs"
