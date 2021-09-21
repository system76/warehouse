defmodule Warehouse.AssemblyService do
  @moduledoc """
  Handles forming the request and parsing the response from the assembly
  microservice gRPC server.
  """

  require Logger

  alias Bottle.Assembly.V1.{ListComponentDemandsRequest, Stub}
  alias Warehouse.AssemblyServiceClient

  @spec request_component_demand() :: List.t() | Stream.t()
  def request_component_demand() do
    request = ListComponentDemandRequest.new(request_id: Bottle.RequestId.write(:queue))

    with {:ok, channel} <- AssemblyServiceClient.channel(),
         {:ok, stream} <- Stub.list_component_demands(channel, request) do
      stream
    else
      {:error, reason} ->
        Logger.error("Unable to get component demand from assembly service", resource: inspect(reason))
        []
    end
  end
end
