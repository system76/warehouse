defmodule Warehouse.Events do
  @moduledoc """
  Encapsulate sending messages over RPC and Rabbit
  """

  require Logger

  alias Bottle.Inventory.V1.{ComponentAvailabilityUpdated}

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

  def broadcast_sku_quantities(_sku_id, _quantities) do
    :ok
  end
end
