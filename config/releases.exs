import Config

producer_config =
  "SQS_PRODUCER"
  |> System.fetch_env!()
  |> Jason.decode!()

config :warehouse,
  producer:
    {BroadwaySQS.Producer,
     queue_url: producer_config["queue_url"],
     config: [
       access_key_id: producer_config["access_key_id"],
       secret_access_key: producer_config["secret_access_key"],
       region: producer_config["region"]
     ]}
