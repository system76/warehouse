defmodule Warehouse.Server do
  use GRPC.Server, service: Bottle.Inventory.V1.Service

  import Ecto.Query

  alias Warehouse.{Repo, Components, Schemas}
  alias Bottle.Inventory.V1.{Component, ComponentAvailabilityListRequest, ComponentAvailabilityListResponse}
  alias GRPC.Server

  @spec component_availability_list(ComponentAvailabilityListRequest.t(), GRPC.Server.Stream.t()) :: any()
  def component_availability_list(%{components: []}, stream) do
    query =
      from c in Schemas.Component,
        where: c.removed == 0

    query
    |> Repo.all()
    |> Stream.map(&calculate_component_availability/1)
    |> Stream.each(&Server.send_reply(stream, &1))
    |> Stream.run()
  end

  defp calculate_component_availability(%Schemas.Component{} = component) do
    ComponentAvailabilityListResponse.new(
      available: Components.number_available(component),
      component: Component.new(id: to_string(component.id)),
      request_id: Bottle.RequestId.write(:queue)
    )
  end
end
