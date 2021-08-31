defmodule Warehouse.BroadwayTest do
  use Warehouse.DataCase

  describe "notify_handler/1 :build_picked" do
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
