defmodule Warehouse.AdditiveMap do
  @moduledoc """
  The `Warehouse.AdditiveMap` module represents a key value storage structure
  where every value is a non_neg_integer. It is used to represent demand and
  availability in the system due to it's helpful utility functions like `add/3`
  and `merge/2`.
  """

  @type key :: String.t()
  @type value :: non_neg_integer()

  @type t :: %{required(key) => value}

  @doc """
  Adds demand to a demand map.

  ## Examples

      iex> add(%{"A" => 1}, "A", 2)
      %{"A" => 3}

      iex> add(%{}, "A", 1)
      %{"A" => 1}

  """
  @spec add(t(), any(), value()) :: t()
  def add(map, key, value) do
    set(map, key, get(map, key) + value)
  end

  @doc """
  Grabs the demand quantity for a given key.

  ## Examples

      iex> get(%{"A" => 1}, "A")
      1

      iex> get(%{}, "A")
      0

  """
  @spec get(t(), any()) :: value()
  def get(map, key) do
    Map.get(map, to_string(key), 0)
  end

  @doc """
  Merges two demand maps. This is very similar to `Map.merge/2` except it sums
  up the values instead of overwrites.

  ## Examples

      iex> merge(%{"A" => 1, "B" => 2}, %{"A" => 4})
      %{"A" => 5, "B" => 2}

      iex> merge(%{"A" => 1, "B" => 2}, %{"C" => 3})
      %{"A" => 1, "B" => 2, "C" => 3}

  """
  @spec merge(t(), t()) :: t()
  def merge(one, two) do
    Enum.reduce(two, one, fn {key, value}, map ->
      add(map, key, value)
    end)
  end

  @doc """
  Sets the exact amount of demand in a demand map.

  ## Examples

      iex> set(%{"A" => 2}, "A", 4)
      %{"A" => 4}

      iex> set(%{}, "A", 2)
      %{"A" => 2}

  """
  @spec set(t(), any(), value()) :: t()
  def set(map, key, value) do
    Map.put(map, to_string(key), value)
  end
end
