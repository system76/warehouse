defmodule Warehouse.ComponentsTest do
  use Warehouse.DataCase

  import Warehouse.Factory

  alias Warehouse.Components

  describe "number_available/1" do
    test "calculates availability for a given component" do
      %{id: component_id} = component = insert(:component)
      sku = insert(:sku)

      insert(:configuration, component: component, quantity: 1, sku: sku)
      insert(:part, sku: sku)

      assert 1 == Components.number_available(component_id)
    end

    test "calculates availability when configurations quantity is > 1" do
      %{id: component_id} = component = insert(:component)
      sku = insert(:sku)

      insert(:configuration, component: component, quantity: 2, sku: sku)
      insert(:part, sku: sku)

      assert 0 == Components.number_available(component_id)

      insert(:part, sku: sku)

      assert 1 == Components.number_available(component_id)
    end

    test "calculates availability with multiple configurations" do
      %{id: component_id} = component = insert(:component)
      sku = insert(:sku)
      another_sku = insert(:sku)

      insert(:configuration, component: component, quantity: 1, sku: sku)
      insert(:configuration, component: component, quantity: 2, sku: another_sku)

      insert(:part, sku: sku)
      insert(:part, sku: another_sku)
      insert(:part, sku: another_sku)

      assert 2 == Components.number_available(component_id)
    end
  end
end
