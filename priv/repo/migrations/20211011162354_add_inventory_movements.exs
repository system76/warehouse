defmodule Warehouse.Repo.Migrations.AddInventoryMovements do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true
  @table_name :inventory_movements

  def change do
    create table(@table_name) do
      add :from_location_id, references(:inventory_locations), null: true
      add :to_location_id, references(:inventory_locations), null: false
      add :part_id, references(:inventory_parts), null: false

      timestamps(updated_at: false)
    end
  end
end
