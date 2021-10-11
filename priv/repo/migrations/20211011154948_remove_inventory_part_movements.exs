defmodule Warehouse.Repo.Migrations.RemoveInventoryPartMovements do
  use Ecto.Migration

  def change do
    drop_if_exists table(:inventory_part_movements)
  end
end
