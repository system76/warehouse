defmodule Warehouse.Repo do
  use Ecto.Repo,
    otp_app: :warehouse,
    adapter: Ecto.Adapters.Postgres
end
