defmodule Warehouse do
  @moduledoc """
  The Warehouse microservice is responsible for handling different parts of
  our inventory system, including:

  - Creating POs with vendors to receive new parts
  - Manage receiving new parts from vendors
  - Manage kitting and the relationship between what we have in inventory and
    what is requested from the e-commerce orders.
  - Calculating and tracking the demand for different SKUs in our system
    (available, back ordered, etc)
  """
end
