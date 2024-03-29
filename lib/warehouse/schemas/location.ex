defmodule Warehouse.Schemas.Location do
  use Ecto.Schema

  alias Warehouse.Schemas.Part

  @type t :: %__MODULE__{
          id: integer(),
          uuid: String.t(),
          name: String.t(),
          area: atom(),
          disabled: boolean(),
          removed: boolean(),
          parts: [Part.t()]
        }

  @type quantity :: %{
          id: integer(),
          uuid: String.t(),
          name: String.t(),
          quantity: non_neg_integer()
        }

  schema "inventory_locations" do
    field :uuid, :string
    field :name, :string

    field :area, Ecto.Enum,
      values: [:assembly, :receiving, :shipped, :shipping, :storage, :transit],
      default: :receiving

    field :disabled, :boolean, default: false
    field :removed, :boolean, default: false

    has_many :parts, Part

    timestamps()
  end
end
