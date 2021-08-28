defmodule Warehouse.Inventory do
  @moduledoc """
  Our public interface to the underlying inventory resources
  """

  require Logger

  import Ecto.Query

  alias Warehouse.{Components, Repo, Schemas}
  alias Bottle.Inventory.V1.{Component, ComponentAvailabilityUpdated, PartCreated, PartUpdated}

  def create_part(%PartCreated{part: part}) do
    broadcast_component_availability_change(part)
  end

  def update_part(%PartUpdated{new: new}) do
    broadcast_component_availability_change(new)
  end

  defp applicable_components(%{sku: %{id: sku_id}}) do
    query =
      from c in Schemas.Configuration,
        join: com in assoc(c, :component),
        where: c.sku_id == ^sku_id,
        preload: [component: com]

    Repo.all(query)
  end

  defp broadcast_component_availability_change(part) do
    part
    |> applicable_components()
    |> Enum.each(&broadcast_availability_change/1)
  end

  defp broadcast_availability_change(%{component: component}) do
    component_id = to_string(component.id)
    %{available: number_available} = Components.number_available(component)

    Logger.info("Component #{component_id} has #{number_available} total available")

    message =
      ComponentAvailabilityUpdated.new(
        quantity: number_available,
        component: Component.new(id: component_id),
        request_id: Bottle.RequestId.write(:queue)
      )

    Bottle.publish(message, source: "warehouse")
  end
end
