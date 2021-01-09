defmodule Warehouse.Server do
  use GRPC.Server, service: Bottle.Inventory.V1.Service

  alias Warehouse.{Repo, Components, Schemas}
  alias Bottle.Inventory.V1.{Component, ComponentAvailabilityListRequest, ComponentAvailabilityListResponse}
  alias GRPC.Server

  @spec component_availability_list(ComponentAvailabilityListRequest.t(), GRPC.Server.Stream.t()) :: any()
  def component_availability_list(%{components: []}, stream) do
    components = Repo.all(Schemas.Component)

    [components: components]
    |> ComponentAvailabilityListRequest.new()
    |> component_availability_list(stream)
  end

  def component_availability_list(%{components: components}, stream) do
    components
    |> Stream.map(&calculate_component_availability/1)
    |> Stream.each(&Server.send_reply(stream, &1))
    |> Stream.run()
  end

  defp calculate_component_availability(%Component{} = component) do
    ComponentAvailabilityListResponse.new(
      available: Components.number_available(component),
      component: component,
      request_id: Bottle.RequestId.write(:queue)
    )
  end
end
