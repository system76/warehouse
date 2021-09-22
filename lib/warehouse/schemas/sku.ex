defmodule Warehouse.Schemas.Sku do
  use Ecto.Schema

  alias Warehouse.Schemas.Part

  @type t :: %__MODULE__{
          id: non_neg_integer(),
          sku: String.t(),
          description: String.t(),
          removed: boolean(),
          parts: [Part.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type quantity :: %{
          available: non_neg_integer(),
          demand: non_neg_integer(),
          excess: non_neg_integer()
        }

  schema "inventory_skus" do
    field :sku, :string
    field :description, :string

    field :removed, :boolean, default: false

    has_many :parts, Part

    timestamps()
  end
end
