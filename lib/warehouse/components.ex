defmodule Warehouse.Components do
  import Ecto.Query

  alias Bottle.Inventory.V1.Component
  alias Warehouse.Repo
  alias Warehouse.Schemas.Configuration

  @spec number_available(String.t() | Component.t()) :: integer
  def number_available(%Component{id: component_id}),
    do: number_available(component_id)

  def number_available(component_id) do
    Configuration
    |> where([c], c.component_id == ^component_id)
    |> Configuration.query_available_parts()
    |> Repo.all()
    |> Enum.map(&Configuration.available_sum/1)
    |> Enum.sum()
  end
end
