defmodule Warehouse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Supervisor.Spec

  require Logger

  def start(_type, _args) do
    children = [
      Warehouse.Repo,
      supervisor(GRPC.Server.Supervisor, [{Warehouse.Endpoint, 50_051}]),
      {Warehouse.Broadway, []}
    ]

    Logger.info("Starting Warehouse")

    opts = [strategy: :one_for_one, name: Warehouse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
