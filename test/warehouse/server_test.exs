defmodule Warehouse.ServerTest do
  use Warehouse.GRPCCase, async: false
  use Warehouse.DataCase, async: false

  alias Bottle.Inventory.V1.{ListComponentAvailabilityRequest, Stub}

  describe "list_component_availability/2" do
    test "streams a list of all needed picking information", %{channel: channel} do
      location_one = insert(:location, area: "storage")
      location_one_id = to_string(location_one.id)
      location_two = insert(:location, area: "storage")
      location_two_id = to_string(location_two.id)
      location_three = insert(:location, area: "storage")
      location_three_id = to_string(location_three.id)

      component = insert(:component)
      component_id = to_string(component.id)

      %{sku: sku_one} = insert(:kit, component: component, quantity: 2)
      sku_one_id = to_string(sku_one.id)
      %{sku: sku_two} = insert(:kit, component: component, quantity: 4)
      sku_two_id = to_string(sku_two.id)

      insert_list(10, :part, sku: sku_one, location: location_one)
      insert_list(31, :part, sku: sku_one, location: location_two)
      insert_list(40, :part, sku: sku_two, location: location_three)

      {:ok, stream} =
        Stub.list_component_availability(
          channel,
          ListComponentAvailabilityRequest.new(components: [%{id: to_string(component.id)}])
        )

      assert [
               %{
                 component: %{id: ^component_id},
                 total_available_quantity: 30,
                 picking_options: [
                   %{
                     sku: %{id: ^sku_one_id},
                     required_quantity_per_kit: 2,
                     available_locations: [
                       %{
                         location: %{id: ^location_one_id},
                         available_quantity: 10
                       },
                       %{
                         location: %{id: ^location_two_id},
                         available_quantity: 31
                       }
                     ]
                   },
                   %{
                     sku: %{id: ^sku_two_id},
                     required_quantity_per_kit: 4,
                     available_locations: [
                       %{
                         location: %{id: ^location_three_id},
                         available_quantity: 40
                       }
                     ]
                   }
                 ]
               }
             ] = Enum.into(stream, [], fn {:ok, response} -> response end)
    end
  end
end
