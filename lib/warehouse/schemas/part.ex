defmodule Warehouse.Schemas.Part do
  use Ecto.Schema

  alias Warehouse.Schemas.{Location, Sku}

  schema "inventory_parts" do
    belongs_to :location, Location
    belongs_to :sku, Sku

    field :assembly_build_id, :integer
    field :rma_description, :string

    timestamps()
  end
end
