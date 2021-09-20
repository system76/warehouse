defmodule Warehouse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children = [
      {SpandexDatadog.ApiServer, [http: HTTPoison, host: "127.0.0.1", batch_size: 20]},
      {DynamicSupervisor, name: Warehouse.SkuSupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: Warehouse.SkuRegistry},
      Warehouse.Repo,
      {GRPC.Server.Supervisor, {Warehouse.Endpoint, 50_051}},
      {Warehouse.Broadway, []}
    ]
    |> maybe_put(Warehouse.AssemblyServiceClient, Application.get_env(:warehouse, :assembly_service_url))

    Logger.info("Starting Warehouse")

    with {:ok, pid} <- Supervisor.start_link(children, opts) do
      warmup()
      {:ok, pid}
    end
  end

  defp warmup do
    :warehouse
    |> Application.get_env(:warmup)
    |> apply([])
  end

  defp maybe_put(list, _value, false), do: list
  defp maybe_put(list, _value, nil), do: list
  defp maybe_put(list, value, _), do: list ++ [value]
end
