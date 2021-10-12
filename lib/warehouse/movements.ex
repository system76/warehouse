defmodule Warehouse.Movements do
  @moduledoc """
  This module is responsible for handling the audit log of part movements thru the warehouse.
  """
  import Ecto.Query

  alias Warehouse.Repo

  alias Warehouse.Schemas.Movement

  @doc """
  Inserts a new part movement from one location to another.
  """
  @spec insert(non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
          {:ok, %Movement{}} | {:error, Ecto.Changeset.t()}
  def insert(part_id, from_location_id, to_location_id) do
    %Movement{}
    |> Movement.changeset(%{
      part_id: part_id,
      from_location_id: from_location_id,
      to_location_id: to_location_id
    })
    |> Repo.insert()
  end

  @spec get_movements_for_sku(String.t(), [{:preloads, [atom()]}]) :: Movement.t()
  def get_movements_for_sku(sku_id, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    query =
      from movement in Movement,
        join: part in assoc(movement, :part),
        where: part.sku_id == ^sku_id,
        preload: ^preloads

    Repo.all(query)
  end
end
