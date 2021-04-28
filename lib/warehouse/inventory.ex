defmodule Warehouse.Inventory do
  @moduledoc """
  Our public interface to the underlying inventory resources
  """

  require Logger

  import Ecto.Query

  alias Warehouse.{Components, Repo, Schemas}
  alias Bottle.Inventory.V1.{Component, ComponentAvailabilityUpdated, PartCreated, PartUpdated}

  def create_part(%PartCreated{part: part}) do
    broadcast_component_availability_change(new_part)
  end

  def update_part(%PartUpdated{new: new}) do
    broadcast_component_availability_change(new)
  end

  defp applicable_components(%{sku: %{id: sku_id}}) do
    query =
      from c in Schemas.Component,
        where: c.sku == ^sku_id

    Repo.all(query)
  end

  defp broadcast_component_availability_change(part) do
    part
    |> applicable_components()
    |> Enum.each(&broadcast_availability_change/1)
  end

  defp broadcast_availability_change(component) do
    component_id = to_string(component.id)
    number_available = Components.number_available(component)

    Logger.info("Component #{component_id} has #{number_available} available")

    message =
      ComponentAvailabilityUpdated.new(
        available: number_available,
        component: Component.new(id: component_id),
        request_id: Bottle.RequestId.write(:queue)
      )

    Bottle.publish(message, source: :warehouse)
  end
end
