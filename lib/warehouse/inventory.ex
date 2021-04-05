defmodule Warehouse.Inventory do
  @moduledoc """
  Our public interface to the underlying inventory resources
  """

  require Logger

  import Ecto.Query

  alias Warehouse.{Caster, Components, Repo, Schemas}
  alias Bottle.Inventory.V1.{Component, ComponentAvailabilityUpdated, PartCreated, PartUpdated}

  def create_part(%PartCreated{part: part}) do
    attrs = Caster.cast(part)
    changeset = Schemas.Part.changeset(%Schemas.Part{}, attrs)

    with {:ok, new_part} <- Repo.insert(changeset) do
      broadcast_component_availability_change(new_part)
    end
  end

  def update_part(%PartUpdated{old: %{id: id}, new: new}) do
    query =
      from p in Schemas.Part,
        where: p.uuid == ^id

    attrs = Caster.cast(new)

    changeset =
      query
      |> Repo.one()
      |> Schemas.Part.changeset(attrs)

    with {:ok, _updated_part} <- Repo.update(changeset) do
      maybe_track_part_movement(changeset)
      maybe_broadcast_availability_changes(changeset)
    end
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

  defp maybe_broadcast_availability_changes(%{changes: changes, data: part}) do
    if Map.has_key?(changes, :assembly_build_id) or Map.has_key?(changes, :location_id) do
      broadcast_component_availability_change(part)
    end
  end

  defp maybe_track_part_movement(%{changes: %{location_id: location_id}, data: %{id: id}}) do
    %Schemas.Movement{}
    |> Schemas.Movement.changeset(%{location: location_id, part_id: id})
    |> Repo.insert()
  end

  defp maybe_track_part_movement(_) do
    :ignored
  end
end
