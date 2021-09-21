defmodule Warehouse.ComponentTest do
  use Warehouse.DataCase

  alias Warehouse.Component

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
end
