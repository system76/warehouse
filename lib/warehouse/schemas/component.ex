defmodule Warehouse.Schemas.Component do
  use Ecto.Schema

  @type t :: %__MODULE__{
          removed: integer()
        }

  schema "components" do
    field :removed, :integer
  end
end
