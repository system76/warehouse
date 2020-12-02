defmodule Warehouse.Schemas.Sku do
  use Ecto.Schema

  alias Warehouse.Schemas.{Manufacturer, Part}

  schema "inventory_skus" do
    field :removed, :boolean, default: false
    field :sku, :string
    field :kind, SkuKindEnum, default: :accessory

    belongs_to :manufacturer, Manufacturer

    has_many :parts, Part

    timestamps()
  end
end
