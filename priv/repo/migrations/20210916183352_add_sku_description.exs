defmodule Warehouse.Repo.Migrations.AddSkuDescription do
  use Ecto.Migration

  def change do
    alter table(:inventory_skus) do
      add :description, :string
    end
  end
end
