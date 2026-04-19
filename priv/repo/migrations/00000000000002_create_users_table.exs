defmodule EzAuth.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users, prefix: "auth") do
      add :name, :string
      add :username, :citext
      add :hashed_password, :string
      add :metadata, :map, null: false, default: %{}
      add :anonymous, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:username], prefix: "auth")
  end
end
