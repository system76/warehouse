defmodule Warehouse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children = [
      {SpandexDatadog.ApiServer, [http: HTTPoison, host: "127.0.0.1", batch_size: 20]},
      {Task.Supervisor, name: Warehouse.TaskSupervisor},
      {Registry, keys: :unique, name: Warehouse.ComponentRegistry},
      {DynamicSupervisor, name: Warehouse.ComponentSupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: Warehouse.SkuRegistry},
      {DynamicSupervisor, name: Warehouse.SkuSupervisor, strategy: :one_for_one},
      Warehouse.Repo,
      {GRPC.Server.Supervisor, {Warehouse.Endpoint, 50_051}},
      {Warehouse.Broadway, []}
    ]

    children =
      if Application.get_env(:warehouse, Warehouse.AssemblyServiceClient)[:enabled?],
        do: children ++ [Warehouse.AssemblyServiceClient],
        else: children

    Logger.info("Starting Warehouse")

    opts = [strategy: :one_for_one, name: Warehouse.Supervisor]

    with {:ok, pid} <- Supervisor.start_link(children, opts),
         :ok <- warmup() do
      {:ok, pid}
    end
  end

  defp warmup do
    :warehouse
    |> Application.get_env(:warmup)
    |> apply([])
  end
end
