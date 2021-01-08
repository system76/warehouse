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
    {BroadwaySQS.Producer,
     queue_url: warehouse_config["SQS_URL"],
     config: [
       access_key_id: warehouse_config["AWS_ACCESS_KEY_ID"],
       secret_access_key: warehouse_config["AWS_SECRET_ACCESS_KEY"],
       region: warehouse_config["AWS_REGION"]
     ]}

config :ex_aws,
  access_key_id: warehouse_config["AWS_ACCESS_KEY_ID"],
  secret_access_key: warehouse_config["AWS_SECRET_ACCESS_KEY"],
  region: warehouse_config["AWS_REGION"]
