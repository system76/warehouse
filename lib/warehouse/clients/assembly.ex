defmodule Warehouse.Clients.Assembly do
  @moduledoc """
  Client for interacting with the Assembly service.
  """

  @callback request_component_demands() :: Enumerable.t()

  def request_component_demands(), do: implementation().request_component_demands()

  def implementation() do
    :warehouse
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:implementation, Warehouse.Clients.Assembly.DefaultClient)
  end
end
