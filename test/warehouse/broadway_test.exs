defmodule Warehouse.BroadwayTest do
  use Warehouse.DataCase, async: true

  describe "notify_handler/1 :build_picked" do
    test "removes any currently assigned parts of build" do
      build_id = 123
      old_part = insert(:part, assembly_build_id: build_id)
      new_part = insert(:part)
      location = insert(:location, area: "assembly")

      message =
        Bottle.Assembly.V1.BuildPicked.new(
          build: %{id: to_string(build_id)},
          location: %{id: to_string(location.uuid)},
          parts: [%{id: to_string(new_part.uuid)}]
        )

      Warehouse.Broadway.notify_handler({:build_picked, message})

      assert %{assembly_build_id: nil} = Repo.get(Warehouse.Schemas.Part, old_part.id)
    end

    test "updates list of parts" do
      parts = insert_list(8, :part)
      part_ids = Enum.map(parts, & &1.id)
      part_uuids = Enum.map(parts, & &1.uuid)
      build_id = 456
      location = insert(:location, area: "assembly")

      message =
        Bottle.Assembly.V1.BuildPicked.new(
          build: %{id: to_string(build_id)},
          location: %{id: to_string(location.uuid)},
          parts: Enum.map(part_uuids, &%{id: to_string(&1)})
        )

      Warehouse.Broadway.notify_handler({:build_picked, message})

      updated_parts = Repo.all(from p in Warehouse.Schemas.Part, where: p.id in ^part_ids)

      assert Enum.all?(updated_parts, fn part ->
               assert to_string(part.assembly_build_id) == to_string(build_id)
               assert to_string(part.location_id) == to_string(location.id)
             end)
    end
  end

  describe "notify_handler/1 :part_updated" do
    test "registers part movement if location changes" do
      %{id: old_location_id} = old_location = insert(:location, area: "assembly")
      %{id: part_id, sku_id: sku_id} = insert(:part, location: old_location)

      %{id: new_location_id} = insert(:location, area: "assembly")

      message =
        Bottle.Inventory.V1.PartUpdated.new(
          old: %{id: to_string(part_id), location: %{id: to_string(old_location_id)}},
          new: %{id: to_string(part_id), sku: %{id: sku_id}, location: %{id: to_string(new_location_id)}}
        )

      Warehouse.Broadway.notify_handler({:part_updated, message})

      assert [
               %{from_location_id: ^old_location_id, to_location_id: ^new_location_id, part_id: ^part_id}
               | _
             ] = Warehouse.Movements.get_movements_for_sku(sku_id)
    end

    test "does not register part movement if location is the same" do
      %{id: location_id} = location = insert(:location, area: "assembly")
      %{id: part_id, sku_id: sku_id} = insert(:part, location: location)

      message =
        Bottle.Inventory.V1.PartUpdated.new(
          old: %{id: to_string(part_id), location: %{id: to_string(location_id)}},
          new: %{
            id: to_string(part_id),
            name: "Changed",
            sku: %{id: to_string(sku_id)},
            location: %{id: to_string(location_id)}
          }
        )

      Warehouse.Broadway.notify_handler({:part_updated, message})

      assert [] = Warehouse.Movements.get_movements_for_sku(sku_id)
    end
  end

  describe "notify_handler/1 :part_created" do
    test "registers part initial part movement" do
      %{id: part_id, sku_id: sku_id, location_id: location_id} = insert(:part)

      message =
        Bottle.Inventory.V1.PartCreated.new(
          part: %{id: to_string(part_id), sku: %{id: to_string(sku_id)}, location: %{id: to_string(location_id)}}
        )

      Warehouse.Broadway.notify_handler({:part_created, message})

      assert [
               %{from_location_id: nil, to_location_id: ^location_id, part_id: ^part_id}
               | _
             ] = Warehouse.Movements.get_movements_for_sku(sku_id)
    end
  end
end
