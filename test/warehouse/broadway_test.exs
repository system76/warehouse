defmodule Warehouse.BroadwayTest do
  use Warehouse.DataCase

  alias Bottle.Assembly.V1.BuildPicked
  alias Bottle.Inventory.V1.ComponentKitChanged
  alias Warehouse.Broadway
  alias Warehouse.Component

  describe "notify_handler/1 :build_picked" do
    test "removes any currently assigned parts of build" do
      build_id = 123
      old_part = insert(:part, assembly_build_id: build_id)
      new_part = insert(:part)
      location = insert(:location, area: "assembly")

      message =
        BuildPicked.new(
          build: %{id: to_string(build_id)},
          location: %{id: to_string(location.uuid)},
          parts: [%{id: to_string(new_part.uuid)}]
        )

      Broadway.notify_handler({:build_picked, message})

      assert %{assembly_build_id: nil} = Repo.get(Warehouse.Schemas.Part, old_part.id)
    end

    test "updates list of parts" do
      parts = insert_list(8, :part)
      part_ids = Enum.map(parts, & &1.id)
      part_uuids = Enum.map(parts, & &1.uuid)
      build_id = 456
      location = insert(:location, area: "assembly")

      message =
        BuildPicked.new(
          build: %{id: to_string(build_id)},
          location: %{id: to_string(location.uuid)},
          parts: Enum.map(part_uuids, &%{id: to_string(&1)})
        )

      Broadway.notify_handler({:build_picked, message})

      updated_parts = Repo.all(from p in Warehouse.Schemas.Part, where: p.id in ^part_ids)

      assert Enum.all?(updated_parts, fn part ->
               assert to_string(part.assembly_build_id) == to_string(build_id)
               assert to_string(part.location_id) == to_string(location.id)
             end)
    end
  end

  describe "notify_handler/1 :component_kit_changed" do
    test "updates component kits" do
      sku = :sku |> insert() |> supervise()
      component = insert(:component)
      %{sku_id: sku_id} = kit = insert(:kit, component: component, sku: sku, quantity: 2)
      supervise(component)

      # Update kit quantity in the DB (Simulates HAL/Joshua update)
      kit
      |> Ecto.Changeset.change(%{quantity: 7})
      |> Repo.update()

      # Quantity is still 2...
      assert [
               %{
                 skus: [
                   %{id: ^sku_id, required_quantity: 2}
                 ]
               }
             ] = Component.get_component_picking_options(component.id)

      # After receiving event from HAL, cache should be updated
      message = ComponentKitChanged.new(component: %{id: component.id})
      Broadway.notify_handler({:component_kit_changed, message})

      assert [
               %{
                 skus: [
                   %{id: ^sku_id, required_quantity: 7}
                 ]
               }
             ] = Component.get_component_picking_options(component.id)
    end
  end
end
