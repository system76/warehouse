defmodule WarehouseBroadway.Handlers do
  @moduledoc """
  The functions actually handling async messages from our RabbitMQ queue.
  """

  import Ecto.Query

  require Logger

  alias Warehouse.{Repo, Components, Schemas}
  alias Bottle.Inventory.V1.{Component, ComponentUpdated}

  defp handle({:part_created, %{part: %{id: part_id, sku: %{id: sku_id}}}}) do
    Logger.metadata(part_id: part_id)
    Logger.info("Handling new part created")

    Configuration
    |> select([:id])
    |> where([c], c.sku_id == ^sku_id)
    |> Repo.all()
    |> Enum.each(&component_quantity_update/1)
  end

  defp component_quantity_update(component_id) do
    quantity = Components.number_available(component_id)

    Logger.info("Calculated new available quantity of #{quantity} for component", component_id: component_id)

    component = Component.new(id: component_id, available_quantity: quantity)
    event = Bottle.Inventory.V1.PartCreated.new(part: ComponentUpdated.new(new: component))
    Bottle.publish(event, source: "Warehouse")
  end

  defp handle({event, _message}) do
    Logger.warn("Ignoring #{event} message")
    :ignored
  end
end
