defmodule Warehouse.KitTest do
  use Warehouse.DataCase

  import Mox

  alias Warehouse.{AdditiveMap, Kit, Sku}

  def set_sku_stock(sku_id, level) do
    stub(Warehouse.MockEvents, :broadcast_component_quantities, fn _, _ -> :ok end)
    stub(Warehouse.MockEvents, :broadcast_sku_quantities, fn _, _ -> :ok end)

    parts =
      insert_list(level, :part, %{
        sku: nil,
        sku_id: sku_id,
        location: insert(:location, area: "storage")
      })

    with [{pid, _value}] <- Registry.lookup(Warehouse.SkuRegistry, to_string(sku_id)) do
      send(pid, :update_available)
    end

    parts
  end

  def sku_stock_fixture(inventory_quantity, kit_quantity \\ 1) do
    sku = :sku |> insert() |> supervise()
    kit = insert(:kit, sku: sku, quantity: kit_quantity)
    set_sku_stock(sku.id, inventory_quantity)

    %{kit: kit, sku: sku}
  end

  describe "get_kit_picking_options/1" do
    test "returns expected data structure" do
      stub(Warehouse.MockEvents, :broadcast_sku_quantities, fn _, _ -> :ok end)

      sku = :sku |> insert() |> supervise()
      location = insert(:location, area: "storage")
      kit = insert(:kit, sku: sku, quantity: 3)

      insert_list(7, :part, sku: sku, location: location)

      Sku.update_sku_availability(sku.id)

      %{sku: sku_sku, description: sku_description} = sku
      %{id: location_id, uuid: location_uuid, name: location_name} = location

      assert %{
               available_quantity: 2,
               required_quantity: 1,
               skus: [
                 %{
                   sku: ^sku_sku,
                   description: ^sku_description,
                   available_quantity: 7,
                   required_quantity: 3,
                   locations: [
                     %{
                       id: ^location_id,
                       uuid: ^location_uuid,
                       name: ^location_name,
                       available_quantity: 7
                     }
                   ]
                 }
               ]
             } = Kit.get_kit_picking_options(kit)
    end
  end

  describe "kit_sku_demand/1" do
    test "gets the demand for each sku" do
      %{sku: %{id: sku_one_id}, kit: kit_one} = sku_stock_fixture(10, 2)
      %{sku: %{id: sku_two_id}, kit: kit_two} = sku_stock_fixture(20)

      demand = Kit.kit_sku_demand([kit_one, kit_two], 25)
      assert AdditiveMap.get(demand, sku_one_id) == 10
      assert AdditiveMap.get(demand, sku_two_id) == 20
    end

    test "adds remaining demand to first sku" do
      %{sku: %{id: sku_one_id}, kit: kit_one} = sku_stock_fixture(6, 2)
      %{sku: %{id: sku_two_id}, kit: kit_two} = sku_stock_fixture(20)

      demand = Kit.kit_sku_demand([kit_one, kit_two], 25)
      assert AdditiveMap.get(demand, sku_one_id) == 10
      assert AdditiveMap.get(demand, sku_two_id) == 20
    end

    test "does not break on lower quantity than demand" do
      %{sku: %{id: sku_one_id}, kit: kit_one} = sku_stock_fixture(0)
      %{sku: %{id: sku_two_id}, kit: kit_two} = sku_stock_fixture(0)

      demand = Kit.kit_sku_demand([kit_one, kit_two], 20)
      assert AdditiveMap.get(demand, sku_one_id) == 20
      assert AdditiveMap.get(demand, sku_two_id) == 0
    end

    test "add zero to all skus in kit list" do
      %{sku: %{id: sku_one_id}, kit: kit_one} = sku_stock_fixture(20)
      %{sku: %{id: sku_two_id}, kit: kit_two} = sku_stock_fixture(0)

      demand = Kit.kit_sku_demand([kit_one, kit_two], 20)
      assert AdditiveMap.get(demand, sku_one_id) == 20
      assert AdditiveMap.get(demand, sku_two_id) == 0
    end
  end

  describe "kit_sku_availability/1" do
    test "gets sku availability of list of skus" do
      %{sku: %{id: sku_one_id}, kit: kit_one} = sku_stock_fixture(10, 4)
      %{sku: %{id: sku_two_id}, kit: kit_two} = sku_stock_fixture(20)

      availability = Kit.kit_sku_availability([kit_one, kit_two])
      assert AdditiveMap.get(availability, sku_one_id) == 2
      assert AdditiveMap.get(availability, sku_two_id) == 20
    end

    test "gets sku availability of single kit" do
      %{sku: %{id: sku_id}, kit: kit} = sku_stock_fixture(10, 2)

      availability = Kit.kit_sku_availability(kit)
      assert AdditiveMap.get(availability, sku_id) == 5
    end
  end
end
