defmodule Warehouse.Components do
  import Ecto.Query

  alias Bottle.Inventory.V1.Component
  alias Warehouse.Repo
  alias Warehouse.Schemas.Configuration

  @spec number_available(Component.t()) :: integer
  def number_available(%Component{id: component_id}) do
    query =
      from c in Configuration,
        join: s in assoc(c, :sku),
        join: p in assoc(s, :parts),
        join: l in assoc(p, :location),
        where: c.component_id == ^component_id,
        where: l.area == :storage,
        preload: [sku: {s, parts: {p, location: l}}]

    query
    |> Repo.all()
    |> Enum.map(&configuration_available/1)
    |> Enum.sum()
  end

  defp configuration_available(%{sku: %{parts: parts}, quantity: quantity}) do
    parts
    |> length()
    |> div(quantity)
  end
end
