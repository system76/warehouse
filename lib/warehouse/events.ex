defmodule Warehouse.Events do
  @moduledoc """
  Encapsulate sending messages over RPC and Rabbit
  """

  require Logger

  alias Bottle.Inventory.V1.{ComponentAvailabilityUpdated, SkuDetailsUpdated}

  @callback broadcast_component_quantities(String.t(), map()) :: :ok
  @callback broadcast_sku_quantities(String.t(), map()) :: :ok

  @source "warehouse"

  def broadcast_component_quantities(component_id, quantities) do
    message =
      ComponentAvailabilityUpdated.new(
        quantity: Map.get(quantities, :available, 0),
        component: %{id: to_string(component_id)},
        request_id: Bottle.RequestId.write(:queue)
      )

    Bottle.publish(message, source: @source)
  end

  def broadcast_sku_quantities(sku_id, quantities) do
    message =
      SkuDetailsUpdated.new(
        request_id: Bottle.RequestId.write(:queue),
        sku: %{id: to_string(sku_id)},
        available_quantity: Map.get(quantities, :available, 0),
        demand_quantity: Map.get(quantities, :demand, 0),
        excess_quantity: Map.get(quantities, :excess, 0)
      )

    Bottle.publish(message, source: @source)
  end
end
