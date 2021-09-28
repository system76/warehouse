defmodule Warehouse.ServerTest do
  use Warehouse.GRPCCase
  use Warehouse.DataCase

  import Mox

  alias Warehouse.{Component, Sku}

  alias Bottle.Inventory.V1.{ListComponentAvailabilityRequest, Stub}

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
end
