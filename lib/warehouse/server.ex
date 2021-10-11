defmodule Warehouse.Server do
  use GRPC.Server, service: Bottle.Inventory.V1.Service

  require Logger

  alias Warehouse.{Caster, Component, Schemas, Sku}

  alias Bottle.Inventory.V1.{
    ListComponentAvailabilityRequest,
    ListComponentAvailabilityResponse,
    ListSkuQuantityRequest,
    ListSkuQuantityResponse,
    ListSkuAvailabilityRequest,
    ListSkuAvailabilityResponse,
    GetSkuDetailsRequest,
    GetSkuDetailsResponse
  }

  alias GRPC.Server

  @spec list_component_availability(ListComponentAvailabilityRequest.t(), GRPC.Server.Stream.t()) :: any()
  def list_component_availability(%{components: components}, stream) do
    components
    |> Enum.map(& &1.id)
    |> Component.list_components()
    |> Enum.map(fn component ->
      availability = Component.get_component_availability(component.id)
      picking_options = Component.get_component_picking_options(component.id)

      ListComponentAvailabilityResponse.new(
        total_available_quantity: availability,
        component: Caster.cast(component),
        request_id: Bottle.RequestId.write(:rpc),
        picking_options: Caster.cast_picking_options(picking_options)
      )
    end)
    |> Enum.each(&Server.send_reply(stream, &1))
  end

  @spec list_sku_quantity(ListSkuQuantityRequest.t(), GRPC.Server.Stream.t()) :: any()
  def list_sku_quantity(_request, stream) do
    Sku.list_skus()
    |> Enum.map(fn sku ->
      quantity = Sku.get_sku_quantity(sku.id)

      ListSkuQuantityResponse.new(
        sku: Caster.cast(sku),
        request_id: Bottle.RequestId.write(:rpc),
        available_quantity: quantity.available,
        demand_quantity: quantity.demand,
        excess_quantity: quantity.excess
      )
    end)
    |> Enum.each(&Server.send_reply(stream, &1))
  end

  @spec list_sku_availability(ListSkuAvailabilityRequest.t(), GRPC.Server.Stream.t()) :: ListSkuAvailabilityResponse.t()
  def list_sku_availability(%{sku: %{id: sku_id}}, _stream) do
    case Sku.get_sku(sku_id) do
      nil ->
        raise GRPC.RPCError, status: :not_found

      sku ->
        locations = Sku.get_sku_pickable_locations(sku.id)
        best_location = hd(locations)

        ListSkuAvailabilityResponse.new(
          sku: Caster.cast(sku),
          request_id: Bottle.RequestId.write(:rpc),
          location: Caster.cast(struct(Schemas.Location, best_location))
        )
    end
  end

  # @spec list_sku_movements(ListSkuAvailabilityRequest.t(), GRPC.Server.Stream.t()) :: ListSkuAvailabilityResponse.t()
  # def list_sku_movements(_sku_id) do
  # :ok
  # end

  @spec get_sku_details(GetSkuDetailsRequest.t(), GRPC.Server.Stream.t()) :: GetSkuDetailsResponse.t()
  def get_sku_details(%{sku: %{id: sku_id}}, _stream) do
    case Sku.get_sku(sku_id) do
      nil ->
        raise GRPC.RPCError, status: :not_found

      sku ->
        quantity = Sku.get_sku_quantity(sku.id)

        GetSkuDetailsResponse.new(
          sku: Caster.cast(sku),
          request_id: Bottle.RequestId.write(:rpc),
          available_quantity: quantity.available,
          demand_quantity: quantity.demand,
          excess_quantity: quantity.excess
        )
    end
  end
end
