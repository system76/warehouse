defmodule Warehouse.Repo.Migrations.AddUuidToLocations do
  use Ecto.Migration

  def change do
    alter table(:inventory_locations) do
      add :uuid, :string
    end

    create unique_index(:inventory_locations, [:uuid])
  end
end
