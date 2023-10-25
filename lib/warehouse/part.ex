defmodule Warehouse.Part do
  @moduledoc """
  This module handles high level functions for `Warehouse.Schemas.Part`.
  """

  import Ecto.Query

  require Logger

  alias Ecto.Multi
  alias Warehouse.{Repo, Schemas, Sku}

  @doc """
  Returns a list of parts that match the given UUIDs. Will raise an
  `Ecto.NoResultsError` if one of the given UUIDs is not found.

  ## Examples

      iex> list_parts!([part_uuid])
      [%Schemas.Part{}]

      iex> list_parts!([non_existant_part_uuid])
      ** (Ecto.NoResultsError)

  """
  def list_parts!(uuids) do
    parts =
      Schemas.Part
      |> where([p], p.uuid in ^uuids)
      |> Repo.all()

    if diff = uuids -- Enum.map(parts, &Map.get(&1, :uuid)) != [] do
      queryable = from p in Schemas.Part, where: p.uuid in ^diff
      raise Ecto.NoResultsError, queryable: queryable
    else
      parts
    end
  end

  @doc """
  Picks a list of part UUIDs for a given build. This function does the
  following:

    - Removes all existing parts from the build
    - Adds all of the given parts to the build
    - Moves all of the given parts to the location
    - Updates sku availability quantities

  All of these actions happen in a database transaction, and will fail if any
  one step fails.

  ## Examples

      iex> pick_parts([part_uuid, part_uuid], build_id, location_uuid)
      :ok

  """
  @spec pick_parts([String.t()], integer(), String.t()) :: :ok | :error
  def pick_parts(part_uuids, build_id, location_uuid) do
    location = Repo.get_by!(Schemas.Location, uuid: location_uuid)

    part_uuids
    |> list_parts!()
    |> Enum.reduce(Multi.new(), add_part_to_build_reducer(build_id, location))
    |> Multi.prepend(remove_parts_from_build(build_id, part_uuids))
    |> Repo.transaction()
    |> report_pick_parts_effects()
  end

  defp remove_parts_from_build(build_id, excluded_uuids) do
    query =
      from p in Schemas.Part,
        where: p.assembly_build_id == ^to_string(build_id),
        where: p.uuid not in ^excluded_uuids

    Multi.update_all(Multi.new(), :remove_parts, query, set: [assembly_build_id: nil])
  end

  defp add_part_to_build_reducer(build_id, location) do
    fn part, multi ->
      multi
      |> Multi.append(add_part_to_build(part, build_id, location.id))
      |> Multi.append(track_part_movement(part, location))
    end
  end

  defp add_part_to_build(part, build_id, location_id) do
    changeset =
      Schemas.Part.changeset(part, %{
        assembly_build_id: to_string(build_id),
        location_id: to_string(location_id)
      })

    Multi.update(Multi.new(), {:update_part, part.id}, changeset)
  end

  defp track_part_movement(part, location) do
    Multi.insert(Multi.new(), {:part_movement, part.id}, %Schemas.Movement{
      location: location,
      part: part
    })
  end

  defp report_pick_parts_effects({:ok, changes}) do
    changes
    |> Enum.map(&report_pick_parts_effects/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Map.get(&1, :sku_id))
    |> Enum.uniq()
    |> Enum.each(&Sku.update_sku_availability/1)
  end

  defp report_pick_parts_effects({:error, failed_operation, failed_value, _changes_so_far}) do
    Logger.error("Unable to update parts",
      resource: %{
        failed_operation: inspect(failed_operation),
        failed_value: inspect(failed_value)
      }
    )

    :error
  end

  defp report_pick_parts_effects({{:update_part, _}, %Schemas.Part{} = part}) do
    Logger.info("Assigned Part to Build",
      part_id: part.uuid,
      build_id: part.assembly_build_id
    )

    part
  end

  defp report_pick_parts_effects(_), do: nil

  @doc """
  Returns the amount of available parts to pick for a given SKU. This equates to
  all parts that:

  - Are in a storage, transit, or receiving location
  - Do not have an RMA description
  - Are not in an excluded picking list (QA, a couple of desks, etc)

  ## Examples

      iex> get_pickable_quantity_for_sku(sku_id)
      10

  """
  @spec get_pickable_quantity_for_sku(String.t()) :: non_neg_integer()
  def get_pickable_quantity_for_sku(sku_id) do
    query =
      from p in Schemas.Part,
        join: l in assoc(p, :location),
        where: p.sku_id == ^sku_id,
        where: is_nil(p.rma_description),
        where: l.area in [:receiving, :transit, :storage],
        where: l.id not in ^excluded_picking_locations()

    Repo.aggregate(query, :count, :id)
  end

  @doc """
  Returns a list of locations that have a pickable quantity of the sku
  available. This is similar to the above `get_pickable_quantity_for_sku/1` but
  returns more information about the locations where those parts are, and as
  such, is a more expensive query.

  ## Examples

      iex> get_pickable_locations_for_sku(sku_id)
      10

  """
  @spec get_pickable_locations_for_sku(String.t()) :: Schemas.Location.quantity()
  def get_pickable_locations_for_sku(sku_id) do
    query =
      from p in Schemas.Part,
        join: l in assoc(p, :location),
        select: %{id: l.id, uuid: l.uuid, name: l.name, quantity: count(p.id)},
        where: p.sku_id == ^sku_id,
        where: is_nil(p.rma_description),
        where: l.area in [:receiving, :transit, :storage],
        where: l.id not in ^excluded_picking_locations(),
        group_by: l.id

    Repo.all(query)
  end

  @doc """
  Returns a list of `Warehouse.Schemas.Location` IDs that are excluded from
  picking.

  ## Examples

      iex> excluded_picking_locations()
      [1, 2, 3]

  """
  def excluded_picking_locations() do
    Application.get_env(:warehouse, :exluded_picking_locations, [])
  end
end
