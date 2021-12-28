defmodule Warehouse.Clients.Assembly.DefaultClient do
  @moduledoc """
  Handles forming the request and parsing the response from the assembly
  microservice gRPC server.
  """

  require Logger

  alias Bottle.Assembly.V1.{ListComponentDemandsRequest, Stub}
  alias Warehouse.Clients.Assembly.Connection

  @behaviour Warehouse.Clients.Assembly

  @impl true
  def request_component_demands() do
    request = ListComponentDemandsRequest.new(request_id: Bottle.RequestId.write(:queue))

    with {:ok, channel} <- Connection.channel(),
         {:ok, stream} <- Stub.list_component_demands(channel, request) do
      Stream.map(stream, &cast/1)
    else
      {:error, reason} ->
        Logger.error("Unable to get component demand from assembly service", resource: inspect(reason))
        Stream.cycle([])
    end
  end

  defp cast({:ok, res}), do: res
end
