defmodule Warehouse.ComponentTest do
  use Warehouse.DataCase

  import Mox

  alias Warehouse.{AdditiveMap, Component}

  def demand_fixture(sku, kit_quantity, component_demand, parts_available) do
    component = insert(:component)
    insert(:kit, component: component, sku: sku, quantity: kit_quantity)
    insert_list(parts_available, :part, sku: sku)

    supervise(component)

    Component.update_component_demand(component.id, component_demand)
  end

  test "list_components/0 lists all components" do
    component = :component |> insert() |> supervise()
    assert Component.list_components() == [component]
  end

  test "list_components/1 filters to list only given component ids" do
    components = 4 |> insert_list(:component) |> supervise()
    _false_components = 8 |> insert_list(:component) |> supervise()

    ids = Enum.map(components, & &1.id)
    assert Component.list_components(ids) == components
  end

  test "warmup_components/0 starts all component supervisors" do
    component = insert(:component)
    assert Warehouse.ComponentRegistry |> Registry.lookup(to_string(component.id)) |> length() == 0

    Component.warmup_components()
    assert Warehouse.ComponentRegistry |> Registry.lookup(to_string(component.id)) |> length() == 1
  end

  test "get_component/1 finds a component by ID" do
    component = :component |> insert() |> supervise()
    assert Component.get_component(component.id) == component
  end

  test "get_component/1 returns nil if component doesn't exist or is not supervised" do
    component = build(:component)
    assert Component.get_component(component.id) == nil
  end

  test "get_sku_demands/0 returns an AdditiveMap of all sku demands" do
    stub(Warehouse.MockEvents, :broadcast_sku_quantities, fn _, _ -> :ok end)

    sku = :sku |> insert() |> supervise()
    demand_fixture(sku, 2, 10, 10)
    demand_fixture(sku, 4, 20, 20)

    demand = Component.get_sku_demands()
    assert AdditiveMap.get(demand, sku.id) == 100
  end

  test "update_component_demand/2 updates the component demand" do
    component = :component |> insert() |> supervise()
    assert :ok = Component.update_component_demand(component.id, 5)
  end
end
