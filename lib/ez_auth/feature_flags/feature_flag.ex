defmodule EzAuth.FeatureFlags.FeatureFlag do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias __MODULE__

  @schema_prefix "auth"
  schema "feature_flags" do
    field(:key, :string)
    field(:description, :string)
    field(:enabled, :boolean, default: false)
    field(:claim, :string)

    timestamps(type: :utc_datetime)
  end

  def by_key_query(key) do
    from(f in FeatureFlag, where: f.key == ^key)
  end

  def changeset(%FeatureFlag{} = flag, attrs) do
    flag
    |> cast(attrs, [:key, :description, :enabled, :claim])
    |> validate_required([:key])
    |> unique_constraint(:key)
  end

  def list_query do
    from(f in FeatureFlag, order_by: [asc: f.key])
  end
end
