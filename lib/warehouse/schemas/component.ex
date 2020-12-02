defmodule Warehouse.Schemas.Component do
  use Ecto.Schema

  alias Warehouse.Schemas.Configuration

  schema "components" do
    has_many :configurations, Configuration
  end
end
