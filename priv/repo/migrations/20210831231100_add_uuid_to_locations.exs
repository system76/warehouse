defmodule Warehouse.Repo.Migrations.AddUuidToLocations do
  use Ecto.Migration

  def change do
    alter table(:inventory_locations) do
      add :uuid, :uuid
    end
  end
end
