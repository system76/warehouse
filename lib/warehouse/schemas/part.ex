defmodule Warehouse.Schemas.Part do
  use Ecto.Schema

  alias Warehouse.Schemas.{Location, Sku}

  schema "inventory_parts" do
    field :purchase_order_line_id, :integer

    belongs_to :location, Location
    belongs_to :sku, Sku

    timestamps()
  end
end
