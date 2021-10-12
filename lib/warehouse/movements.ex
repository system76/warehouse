defmodule Warehouse.Movements do
  alias Warehouse.Repo

  alias Warehouse.Schemas.Movement

  def insert(part_id, from_location_id, to_location_id) do
    %Movement{}
    |> Movement.changeset(%{
      part_id: part_id,
      from_location_id: from_location_id,
      to_location_id: to_location_id
    })
    |> Repo.insert()
  end
end
