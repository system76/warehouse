defmodule Warehouse.Schemas.Manufacturer do
  use Ecto.Schema

  alias Warehouse.Schemas.Sku

  schema "inventory_manufacturers" do
    field :name, :string

    has_many :skus, Sku

    timestamps()
  end
end
