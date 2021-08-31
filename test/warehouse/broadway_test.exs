defmodule Warehouse.BroadwayTest do
  use Warehouse.DataCase

  describe "notify_handler/1 :build_picked" do
    test "removes any currently assigned parts of build" do
      build_id = Ecto.UUID.generate()
      old_part = insert(:part, assembly_build_id: build_id)
      new_part = insert(:part)
      location = insert(:location, area: "assembly")

      message =
        Bottle.Assembly.V1.BuildPicked.new(
          build: %{id: to_string(build_id)},
          location: %{id: to_string(location.id)},
          parts: [%{id: to_string(new_part.id)}]
        )

      Warehouse.Broadway.notify_handler({:build_picked, message})

      assert %{assembly_build_id: nil} = Repo.get(Warehouse.Schemas.Part, old_part.id)
    end

    test "updates list of parts" do
      parts = insert_list(8, :part)
      part_ids = Enum.map(parts, & &1.id)
      build_id = Ecto.UUID.generate()
      location = insert(:location, area: "assembly")

      message =
        Bottle.Assembly.V1.BuildPicked.new(
          build: %{id: to_string(build_id)},
          location: %{id: to_string(location.id)},
          parts: Enum.map(part_ids, &%{id: to_string(&1)})
        )

      Warehouse.Broadway.notify_handler({:build_picked, message})

      updated_parts = Repo.all(from p in Warehouse.Schemas.Part, where: p.id in ^part_ids)

      assert Enum.all?(updated_parts, fn part ->
               assert to_string(part.assembly_build_id) == to_string(build_id)
               assert to_string(part.location_id) == to_string(location.id)
             end)
    end
  end
end
