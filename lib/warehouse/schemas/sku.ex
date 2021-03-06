defmodule Warehouse.Schemas.Sku do
  use Ecto.Schema

  schema "inventory_skus" do
    field :removed, :boolean, default: false
    field :sku, :string

    has_many :parts, Part

    timestamps()
  end
end
