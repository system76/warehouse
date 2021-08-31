defmodule Warehouse.Inventory do
  @moduledoc """
  Our public interface to the underlying inventory resources
  """

  require Logger

  import Ecto.Query

  alias Ecto.Multi
  alias Warehouse.{Components, Repo, Schemas}
  alias Bottle.Inventory.V1.{Component, ComponentAvailabilityUpdated, PartCreated, PartUpdated}

  def create_part(%PartCreated{part: part}) do
    broadcast_component_availability_change(part)
  end

  def update_part(%PartUpdated{new: new}) do
    broadcast_component_availability_change(new)
  end

  def pick_parts(parts, %{id: build_id}, %{id: location_id}) when is_list(parts) do
    part_ids = Enum.map(parts, &Map.get(&1, :id))

    parts =
      Repo.all(
        from p in Schemas.Part,
          join: s in assoc(p, :sku),
          where: p.id in ^part_ids,
          preload: [sku: s]
      )

    update_multi =
      Enum.reduce(parts, Multi.new(), fn part, multi ->
        Multi.update(multi, {:account, part.id}, pick_part_changeset(part, build_id, location_id))
      end)

    case Repo.transaction(update_multi) do
      {:ok, _changes} ->
        parts
        |> Enum.uniq_by(&Map.get(&1, :sku_id))
        |> Enum.each(&broadcast_component_availability_change/1)

        :ok

      {:error, _failed_operation, _failed_value, _changes_so_far} ->
        {:error, "Unable to update parts"}
    end
  end

  defp pick_part_changeset(part, build_id, location_id) do
    Schemas.Part.changeset(part, %{
      assembly_build_id: build_id,
      location_id: location_id
    })
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
