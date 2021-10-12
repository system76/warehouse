defmodule Warehouse.ServerTest do
  use Warehouse.GRPCCase
  use Warehouse.DataCase

  import Mox

  alias Warehouse.{Component, Sku}

  alias Bottle.Inventory.V1.{ListComponentAvailabilityRequest, ListSkuMovementsRequest, Stub}

  describe "list_component_availability/2" do
    test "streams a list of all needed picking information", %{channel: channel} do
      stub(Warehouse.MockEvents, :broadcast_component_quantities, fn _, _ -> :ok end)
      stub(Warehouse.MockEvents, :broadcast_sku_quantities, fn _, _ -> :ok end)

      location_one = insert(:location, area: "storage")
      location_two = insert(:location, area: "storage")
      location_three = insert(:location, area: "storage")

      component = :component |> insert() |> supervise()

      %{sku: sku_one} = kit_one = insert(:kit, component: component, quantity: 2)
      %{sku: sku_two} = kit_two = insert(:kit, component: component, quantity: 4)

      insert_list(10, :part, sku: sku_one, location: location_one)
      insert_list(31, :part, sku: sku_one, location: location_two)
      insert_list(40, :part, sku: sku_two, location: location_three)

      supervise(sku_one)
      supervise(sku_two)

      Sku.update_sku_availability(sku_one.id)
      Sku.update_sku_availability(sku_two.id)
      Component.update_component_kits(component.id, [kit_one, kit_two])

      Process.sleep(1000)

      location_one_uuid = to_string(location_one.uuid)
      location_two_uuid = to_string(location_two.uuid)
      location_three_uuid = to_string(location_three.uuid)

      component_id = to_string(component.id)

      sku_one_id = to_string(sku_one.id)
      sku_two_id = to_string(sku_two.id)

      {:ok, stream} =
        Stub.list_component_availability(
          channel,
          ListComponentAvailabilityRequest.new(components: [%{id: component_id}])
        )

      assert [
               %{
                 component: %{id: ^component_id},
                 total_available_quantity: 30,
                 picking_options: [
                   %{
                     available_quantity: 20,
                     required_quantity: 1,
                     skus: [
                       %{
                         sku: %{id: ^sku_one_id},
                         available_quantity: 41,
                         required_quantity: 2,
                         locations: [
                           %{
                             location: %{id: ^location_one_uuid},
                             available_quantity: 10
                           },
                           %{
                             location: %{id: ^location_two_uuid},
                             available_quantity: 31
                           }
                         ]
                       }
                     ]
                   },
                   %{
                     available_quantity: 10,
                     required_quantity: 1,
                     skus: [
                       %{
                         sku: %{id: ^sku_two_id},
                         available_quantity: 40,
                         required_quantity: 4,
                         locations: [
                           %{
                             location: %{id: ^location_three_uuid},
                             available_quantity: 40
                           }
                         ]
                       }
                     ]
                   }
                 ]
               }
             ] = Enum.into(stream, [], fn {:ok, response} -> response end)
    end
  end

  describe "list_sku_movements/2" do
    test "streams a list of movements", %{channel: channel} do
      part = insert(:part)
      [location_one, location_two, location_three, location_four] = insert_list(4, :location, area: "storage")

      movement_one = insert(:movement, part: part, from_location: location_one, to_location: location_two)
      movement_two = insert(:movement, part: part, from_location: location_two, to_location: location_three)
      movement_three = insert(:movement, part: part, from_location: location_three, to_location: location_four)

      movement_id_one = to_string(movement_one.id)
      movement_id_two = to_string(movement_two.id)
      movement_id_three = to_string(movement_three.id)

      supervise(part.sku)

      {:ok, stream} =
        Stub.list_sku_movements(
          channel,
          ListSkuMovementsRequest.new(sku: %{id: to_string(part.sku_id)})
        )

      assert [
               %Bottle.Inventory.V1.ListSkuMovementsResponse{
                 movements: [
                   %Bottle.Inventory.V1.Movement{
                     id: ^movement_id_one,
                     from_location: %{id: _},
                     inserted_at: _
                   },
                   %Bottle.Inventory.V1.Movement{
                     id: ^movement_id_two,
                     from_location: %{id: _},
                     to_location: %{id: _},
                     inserted_at: _
                   },
                   %Bottle.Inventory.V1.Movement{
                     id: ^movement_id_three,
                     from_location: %{id: _},
                     to_location: %{id: _},
                     inserted_at: _
                   }
                 ]
               }
             ] = Enum.into(stream, [], fn {:ok, response} -> response end)
    end

    test "errors if sku is not found", %{channel: channel} do
      {:error, %GRPC.RPCError{message: "Some requested entity (e.g., file or directory) was not found", status: 5}} =
        Stub.list_sku_movements(
          channel,
          ListSkuMovementsRequest.new(sku: %{id: "n0p3"})
        )
    end
  end
end
