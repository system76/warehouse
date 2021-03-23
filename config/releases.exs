import Config

warehouse_config =
  "CONFIG"
  |> System.fetch_env!()
  |> Jason.decode!()

config :warehouse, Warehouse.Repo,
  username: warehouse_config["DB_USER"],
  password: warehouse_config["DB_PASS"],
  database: warehouse_config["DB_NAME"],
  hostname: warehouse_config["DB_HOST"],
  port: warehouse_config["DB_PORT"],
  pool_size: warehouse_config["DB_POOL"]

config :warehouse,
  producer:
    {BroadwayRabbitMQ.Producer,
     queue: warehouse_config["RABBITMQ_QUEUE_NAME"],
     on_failure: :reject_and_requeue,
     connection: [
       username: warehouse_config["RABBITMQ_USERNAME"],
       password: warehouse_config["RABBITMQ_PASSWORD"],
       host: warehouse_config["RABBITMQ_HOST"],
       port: warehouse_config["RABBITMQ_PORT"],
       ssl_options: [verify: :verify_none]
     ]}

config :appsignal, :config,
  push_api_key: warehouse_config["APPSIGNAL_KEY"],
  env: warehouse_config["ENVIRONMENT"]
