defmodule EzAuth.Migrations.PrepareDatabase do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""
    execute "CREATE SCHEMA IF NOT EXISTS auth", "DROP SCHEMA IF EXISTS auth"
  end
end
