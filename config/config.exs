use Mix.Config

config :copy_cat,
  producer:
    {BroadwaySQS.Producer,
     queue_url: "",
     config: [
       access_key_id: "",
       secret_access_key: "",
       region: "us-east-2"
     ]}

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info

config :appsignal, :config,
  active: false,
  name: "Copy Cat"

import_config "#{Mix.env()}.exs"
