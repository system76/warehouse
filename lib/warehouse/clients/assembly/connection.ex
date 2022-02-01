defmodule Warehouse.Clients.Assembly.Connection do
  @moduledoc """
  A basic GenServer responsible for keeping the HTTPS gRPC connection to the
  assembly microservice alive.
  """

  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def channel() do
    GenServer.call(__MODULE__, :channel)
  end

  @impl true
  def init(_) do
    Logger.info("Warehouse.Clients.Assembly.Connection connecting to gateway at #{config(:url)}")

    case GRPC.Stub.connect(config(:url), assembly_service_options()) do
      {:ok, channel} ->
        Logger.info("Warehouse.Clients.Assembly.Connection connected")
        {:ok, channel}

      {:error, error} ->
        Logger.error("Warehouse.Clients.Assembly.Connection could not connect: #{error}")
        Process.sleep(5000)
        init(%{})
    end
  end

  @impl true
  def handle_info({:gun_down, _, _, _, _}, _state) do
    Logger.info("Warehouse.Clients.Assembly.Connection disconnected")

    with {:ok, channel} <- init(%{}) do
      {:noreply, channel}
    end
  end

  @impl true
  def handle_info({:gun_up, _, _, _, _}, _state) do
    Logger.info("Warehouse.Clients.Assembly.Connection connected")

    with {:ok, channel} <- init(%{}) do
      {:noreply, channel}
    end
  end

  @impl true
  def handle_call(:channel, _from, channel) do
    {:reply, channel, channel}
  end

  defp assembly_service_options() do
    options = [
      interceptors: [GRPC.Logger.Client]
    ]

    if config(:ssl, true) do
      Keyword.put(options, :cred, GRPC.Credential.new([]))
    else
      options
    end
  end

  defp config(key, default \\ nil) do
    config = Application.get_env(:warehouse, __MODULE__)
    Keyword.get(config, key, default)
  end
end
