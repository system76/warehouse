defmodule Warehouse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children = [
      {SpandexDatadog.ApiServer, [http: HTTPoison, host: "127.0.0.1", batch_size: 2]},
      Warehouse.Repo,
      {GRPC.Server.Supervisor, {Warehouse.Endpoint, 50_051}},
      {Warehouse.Broadway, []}
    ]

    Logger.info("Starting Warehouse")

    opts = [strategy: :one_for_one, name: Warehouse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
