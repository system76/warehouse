defmodule Warehouse.Server do
  use GRPC.Server, service: Bottle.Inventory.V1.Service

  alias Bottle.Inventory.V1.{Component, ComponentAvailabilityListRequest, ComponentAvailabilityListResponse}
  alias GRPC.Server
  alias Warehouse.Components

  @spec component_availability_list(ComponentAvailabilityListRequest.t(), GRPC.Server.Stream.t()) :: any()
  def component_availability_list(%{components: []}, stream) do
    calculate_availability(Components.all(), stream)
  end

  def component_availability_list(%{components: components}, stream) do
    calculate_availability(components, stream)
  end

  defp calculate_availability(components, stream) do
    components
    |> Stream.map(&calculate_component_availability/1)
    |> Stream.each(&Server.send_reply(stream, &1))
    |> Stream.run()
  end

  defp calculate_component_availability(%{id: component_id}) do
    calculate_component_availability(component_id)
  end

  defp calculate_component_availability(component_id) do
    ComponentAvailabilityListResponse.new(
      available: Components.number_available(component_id),
      component: Component.new(id: component_id),
      request_id: Bottle.RequestId.write(:queue)
    )
  end
end
