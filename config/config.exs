import Config

config :warehouse,
  env: Mix.env(),
  ecto_repos: [Warehouse.Repo]

config :warehouse,
  producer: {BroadwayRabbitMQ.Producer, queue: "", connection: []}

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info

config :grpc, start_server: true

config :ex_aws,
  access_key_id: nil,
  secret_access_key: nil,
  region: nil

config :appsignal, :config,
  active: false,
  ignore_errors: ["Ecto.NoResultsError"],
  name: "Warehouse"

import_config "#{Mix.env()}.exs"
