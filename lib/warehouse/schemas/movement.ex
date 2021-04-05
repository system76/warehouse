defmodule Warehouse.Schemas.Movement do
  use Ecto.Schema

  import Ecto.Changeset

  alias Warehouse.Schemas.{Location, Part}

  schema "inventory_part_movements" do
    belongs_to :location, Location
    belongs_to :part, Part

    timestamps(updated_at: false)
  end

  def changeset(part, attrs) do
    part
    |> cast(attrs, [:location_id, :part_id])
    |> validate_required([:location_id, :part_id])
    |> assoc_constraint(:sku)
    |> assoc_constraint(:location)
  end
end
