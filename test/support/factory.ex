defmodule Warehouse.Factory do
  use ExMachina.Ecto, repo: Warehouse.Repo

  alias Warehouse.Schemas.{
    Component,
    Configuration,
    Location,
    Part,
    Sku
  }

  def component_factory do
    %Component{}
  end

  def configuration_factory do
    %Configuration{
      quantity: 1,
      sku: build(:sku)
    }
  end

  def location_factory do
    %Location{
      area: :storage,
      disabled: false,
      name: sequence(:name, &"location#{&1}"),
      removed: false
    }
  end

  def part_factory do
    %Part{
      location: build(:location),
      purchase_order_line_id: 1_000_001,
      sku: build(:sku)
    }
  end

  def sku_factory do
    %Sku{
      manufacturer_id: 1_000_001,
      removed: false,
      sku: sequence(:sku, &"sku#{&1}")
    }
  end
end
