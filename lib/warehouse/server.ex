defmodule Warehouse.Server do
  use GRPC.Server, service: Bottle.Inventory.V1.Service

  require Logger

  import Ecto.Query

  alias Warehouse.{Repo, Components, Schemas}
  alias Bottle.Inventory.V1.ListComponentAvailabilityResponse
  alias GRPC.Server

  @spec list_component_availability(ListComponentAvailabilityRequest.t(), GRPC.Server.Stream.t()) :: any()
  def list_component_availability(%{components: components}, stream) do
    component_ids = Enum.map(components, & &1.id)

    query =
      from c in Schemas.Component,
        where: c.removed == false,
        where: c.id in ^component_ids

    Repo.transaction(
      fn ->
        query
        |> Repo.stream()
        |> Stream.map(&calculate_component_availability/1)
        |> Stream.each(&Server.send_reply(stream, &1))
        |> Stream.run()
      end,
      timeout: :infinity
    )
  end

  defp calculate_component_availability(%Schemas.Component{} = component) do
    component_id = to_string(component.id)
    %{available: number_available, options: options} = Components.number_available(component)

    Logger.info("Component #{component_id} has #{number_available} total available")

    ListComponentAvailabilityResponse.new(
      total_available_quantity: number_available,
      component: %{id: component_id},
      request_id: Bottle.RequestId.write(:rpc),
      picking_options: options
    )
  end
end
