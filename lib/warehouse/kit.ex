defmodule Warehouse.Kit do
  @moduledoc """
  Handles high level functions related to `Warehouse.Schemas.Kit`. This includes
  calculating demand for skus in a kit, and updating kit information.
  """

  import Ecto.Query

  alias Warehouse.{Demand, Repo}
  alias Warehouse.Schemas.{Component, Kit, Sku}

  @type demand :: %{required(String.t()) => non_neg_integer()}

  @doc """
  Returns a map of skus in the kit, and the demand they have.

  ## Examples

      iex> kit_sku_demands([%Kit{sku: %{id: "A"}}, %Kit{sku: %{id: "B"}}])
      %{"A" => 1, "B" => 0}

  """
  @spec kit_demands([Kit.t]) :: demand
  def kit_demands(kits) when is_list(kits) do
    kits
    |> Enum.map(&kit_demands/1)
    |> Enum.reduce(&Demand.merge_demands/1)
  end

  def kit_demands(%Kit{} = kit) do

  end
end
