defmodule Warehouse.SkuTest do
  use Warehouse.DataCase

  alias Warehouse.Sku

  test "list_skus/0 lists all skus" do
    sku = :sku |> insert() |> supervise()
    assert Sku.list_skus() == [sku]
  end

  test "list_skus/1 filters to list only given sku ids" do
    skus = 4 |> insert_list(:sku) |> supervise()
    _false_skus = 8 |> insert_list(:sku) |> supervise()

    ids = Enum.map(skus, & &1.id)
    assert Sku.list_skus(ids) == skus
  end

  test "warmup_skus/0 starts all sku supervisors" do
    sku = insert(:sku)
    assert Warehouse.SkuRegistry |> Registry.lookup(to_string(sku.id)) |> length() == 0

    Sku.warmup_skus()
    assert Warehouse.SkuRegistry |> Registry.lookup(to_string(sku.id)) |> length() == 1
  end

  test "get_sku/1 finds a sku by ID" do
    sku = :sku |> insert() |> supervise()
    assert Sku.get_sku(sku.id) == sku
  end

  test "get_sku/1 returns nil if sku doesn't exist or is not supervised" do
    sku = build(:sku)
    assert Sku.get_sku(sku.id) == nil
  end
end
