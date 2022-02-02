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
    channel = Connection.channel()
    request = ListComponentDemandsRequest.new(request_id: Bottle.RequestId.write(:queue))

    case Stub.list_component_demands(channel, request) do
      {:ok, stream} ->
        Stream.map(stream, &cast/1)

      {:error, reason} ->
        Logger.error("Unable to get component demand from assembly service", resource: inspect(reason))
        Stream.cycle([])
    end
  end

  defp cast({:ok, res}), do: res
end
