defmodule Warehouse.PartTest do
  use Warehouse.DataCase

  import ExUnit.CaptureLog
  import Mox

  alias Warehouse.{Part, Sku}

  setup :verify_on_exit!

  describe "list_parts!/1" do
    test "fetches a list of parts by the UUID" do
      parts = insert_list(2, :part)
      db_parts = Part.list_parts!(Enum.map(parts, &Map.get(&1, :uuid)))
      assert length(db_parts) == 2
    end

    test "raises Ecto.NoResultsError if part is not found" do
      part = insert(:part)
      fake_part = build(:part, uuid: Ecto.UUID.generate())

      assert_raise Ecto.NoResultsError, fn ->
        Part.list_parts!([part.uuid, fake_part.uuid])
      end
    end
  end

  describe "pick_parts!/3" do
    test "removes any currently assigned parts on a build" do
      old_part = insert(:part, assembly_build_id: 123)
      new_part = insert(:part)
      location = insert(:location, area: "assembly")

      Part.pick_parts([new_part.uuid], 123, location.uuid)

      assert %{assembly_build_id: nil} = Repo.get(Warehouse.Schemas.Part, old_part.id)
    end

    test "logs that a part was assigned to build" do
      part = insert(:part)
      location = insert(:location, area: "assembly")

      assert capture_log(fn ->
               Part.pick_parts([part.uuid], 123, location.uuid)
             end) =~ "Assigned Part to Build"
    end

    test "updates the sku availability" do
      expect(Warehouse.MockEvents, :broadcast_sku_quantities, 2, fn _, _ -> :ok end)

      sku = :sku |> insert() |> supervise()
      storage_location = insert(:location, area: "storage")
      parts = insert_list(4, :part, sku: sku, sku_id: sku.id, location: storage_location)
      location = insert(:location, area: "assembly")

      Sku.update_sku_availability(sku.id)
      Part.pick_parts([hd(parts).uuid], 423, location.uuid)

      # Pretty ugly but we need to wait for the sku to process the message
      Process.sleep(1000)
    end

    test "raises error if a part uuid is not found" do
      part = build(:part)
      location = insert(:location, area: "assembly")

      assert_raise Ecto.NoResultsError, fn ->
        Part.pick_parts([part.uuid], 123, location.uuid)
      end
    end
  end
end
