defmodule Warehouse.Schemas.Location do
  use Ecto.Schema

  schema "inventory_locations" do
    field :area, AreaEnum, default: :receiving
    field :disabled, :boolean, default: false
    field :removed, :boolean, default: false

    has_many :parts, Part

    timestamps()
  end
end
