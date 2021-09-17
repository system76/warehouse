defmodule Warehouse.Demand do
  @moduledoc """
  Handles high level functions related to sku demand. This is a non persistant
  value that is calculated based on what assembly builds require.
  """

  @type demand :: non_neg_integer()
  @type demand_map :: %{required(String.t()) => demand()}

  @doc """
  Merges two demand maps. This is very similar to `Map.merge/2` except it sums
  up the values instead of overwrites.

  ## Examples

      iex> merge_demands(%{"A" => 1, "B" => 2}, %{"A" => 4})
      %{"A" => 5, "B" => 2}

      iex> merge_demands(%{"A" => 1, "B" => 2}, %{"C" => 3})
      %{"A" => 1, "B" => 2, "C" => 3}

  """
  @spec merge_demands(demand_map(), demand_map()) :: demand_map()
  def merge_demands(one, two) do
    Enum.reduce(two, one, fn {sku, demand}, demand_map ->
      add_demand(demand_map, sku, demand)
    end)
  end

  @doc """
  Adds demand to a demand map.

  ## Examples

      iex> add_demand(%{"A" => 1}, "A", 2)
      %{"A" => 3}

      iex> add_demand(%{}, "A", 1)
      %{"A" => 1}

  """
  def add_demand(map, sku, demand) do
    current = Map.get(map, sku, 0)
    Map.put(map, sku, current + demand)
  end
end
