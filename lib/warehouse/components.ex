defmodule Warehouse.Components do
  import Ecto.Query

  alias Warehouse.Repo
  alias Warehouse.Schemas.{Component, Kit}

  @spec number_available(Component.t()) :: %{available: integer, options: [map()]}
  def number_available(%Component{id: component_id}) do
    query =
      from c in Kit,
        join: s in assoc(c, :sku),
        join: p in assoc(s, :parts),
        join: l in assoc(p, :location),
        where: c.component_id == ^component_id,
        # where: is_nil(p.assembly_build_id),
        where: is_nil(p.rma_description),
        where: l.area == :storage,
        where: l.id not in ^excluded_picking_locations(),
        preload: [sku: {s, parts: {p, location: l}}]

    results = Repo.all(query)

    options = Enum.map(results, &picking_options/1)

    total =
      results
      |> Enum.map(&configuration_available/1)
      |> Enum.sum()

    %{available: total, options: options}
  end

  defp excluded_picking_locations() do
    Application.get_env(:warehouse, :exluded_picking_locations, [])
  end

  defp configuration_available(%{sku: %{parts: parts}, quantity: quantity}) do
    parts
    |> length()
    |> div(quantity)
  end

  defp picking_options(%{sku: sku, quantity: needed_quantity}) do
    locations =
      sku.parts
      |> Enum.group_by(& &1.location_id)
      |> Enum.map(fn {_, parts} -> {length(parts), parts} end)
      |> Enum.sort_by(fn {length, _parts} -> length end)

    %{
      sku: %{
        id: to_string(sku.id),
        name: sku.sku,
        description: sku.description
      },
      required_quantity_per_kit: needed_quantity,
      available_locations:
        Enum.map(locations, fn {quantity, parts} ->
          %{
            location: %{
              id: to_string(hd(parts).location_id),
              name: hd(parts).location.name
            },
            available_quantity: quantity
          }
        end)
    }
  end
end
