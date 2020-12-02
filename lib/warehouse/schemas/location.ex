defmodule Warehouse.Schemas.Location do
  use Ecto.Schema

  alias Warehouse.Schemas.Part

  schema "inventory_locations" do
    field :name, :string
    field :area, AreaEnum, default: :receiving
    field :disabled, :boolean, default: false
    field :removed, :boolean, default: false

    has_many :parts, Part

    timestamps()
  end
end
