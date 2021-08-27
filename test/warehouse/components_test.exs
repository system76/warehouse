defmodule Warehouse.ComponentsTest do
  use Warehouse.DataCase

  describe "number_available/1" do
    test "only includes storage locations in part quantity results" do
      storage_location = insert(:location, area: "storage")
      assembly_location = insert(:location, area: "assembly")

      component = insert(:component)

      %{sku: sku} = insert(:configuration, component: component, quantity: 2)

      insert_list(10, :part, sku: sku, location: storage_location)
      insert_list(200, :part, sku: sku, location: assembly_location)

      assert %{available: 5} = Warehouse.Components.number_available(component)
    end

    test "takes multiple configurations into account for total results" do
      location = insert(:location, area: "storage")
      component = insert(:component)

      %{sku: sku_one} = insert(:configuration, component: component, quantity: 2)
      %{sku: sku_two} = insert(:configuration, component: component, quantity: 4)

      insert_list(10, :part, sku: sku_one, location: location)
      insert_list(8, :part, sku: sku_two, location: location)

      assert %{available: 7} = Warehouse.Components.number_available(component)
    end

    test "returns all available kits and locations" do
      location_one = insert(:location, area: "storage")
      location_one_id = to_string(location_one.id)
      location_two = insert(:location, area: "storage")
      location_two_id = to_string(location_two.id)
      location_three = insert(:location, area: "storage")
      location_three_id = to_string(location_three.id)

      component = insert(:component)
      component_id = to_string(component.id)

      %{sku: sku_one} = insert(:configuration, component: component, quantity: 2)
      sku_one_id = to_string(sku_one.id)
      %{sku: sku_two} = insert(:configuration, component: component, quantity: 4)
      sku_two_id = to_string(sku_two.id)

      insert_list(10, :part, sku: sku_one, location: location_one)
      insert_list(31, :part, sku: sku_one, location: location_two)
      insert_list(40, :part, sku: sku_two, location: location_three)

      assert %{
               available: 30,
               options: [
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
             } = Warehouse.Components.number_available(component)
    end
  end
end
