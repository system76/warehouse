defmodule Warehouse.Schemas.Sku do
  use Ecto.Schema

  alias Warehouse.Schemas.Part

  @type t :: %__MODULE__{
          parts: [Part.t()],
          removed: boolean(),
          sku: String.t()
        }

  schema "inventory_skus" do
    field :removed, :boolean, default: false
    field :sku, :string

    has_many :parts, Part

    timestamps()
  end
end
