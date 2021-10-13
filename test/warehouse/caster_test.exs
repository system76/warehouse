defmodule Warehouse.CasterTest do
  use Warehouse.DataCase

  alias Bottle.Inventory.V1.Movement, as: MovementProto
  alias Bottle.Inventory.V1.Location, as: LocationProto
  alias Bottle.Inventory.V1.Part, as: PartProto
  alias Warehouse.Caster

  describe "cast/1" do
    test "casts Movement struct" do
      movement = insert(:movement)

      id = to_string(movement.id)
      inserted_at = NaiveDateTime.to_iso8601(movement.inserted_at)

      assert %MovementProto{
               id: ^id,
               from_location: %LocationProto{id: _, name: "Test"},
               to_location: %LocationProto{id: _, name: "Test"},
               part: %PartProto{id: _},
               inserted_at: ^inserted_at
             } = Caster.cast(movement)
    end

    test "handles nil from_location" do
      movement = insert(:movement, from_location: nil)

      id = to_string(movement.id)
      inserted_at = NaiveDateTime.to_iso8601(movement.inserted_at)

      assert %MovementProto{
               id: ^id,
               from_location: nil,
               to_location: %LocationProto{id: _, name: "Test"},
               part: %PartProto{id: _},
               inserted_at: ^inserted_at
             } = Caster.cast(movement)
    end
  end
end
