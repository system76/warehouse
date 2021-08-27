defmodule Warehouse.Factory do
  use ExMachina.Ecto, repo: Warehouse.Repo

  alias Warehouse.Schemas.{Component, Configuration, Location, Part, Sku}

  def component_factory do
    %Component{}
  end

  def configuration_factory do
    %Configuration{
      component: build(:component),
      sku: build(:sku),
      quantity: 1
    }
  end

  def location_factory do
    %Location{
      area: :assembly,
      disabled: false,
      removed: false
    }
  end

  def part_factory do
    %Part{
      sku: build(:sku),
      location: build(:location)
    }
  end

  def sku_factory do
    %Sku{
      removed: false,
      sku: sequence(:sku, &"sku#{&1}")
    }
  end
end
