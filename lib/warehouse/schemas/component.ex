defmodule Warehouse.Schemas.Component do
  use Ecto.Schema

  schema "components" do
    field :removed, :integer
  end
end
