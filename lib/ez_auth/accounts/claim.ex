defmodule EzAuth.Accounts.Claim do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias __MODULE__
  alias EzAuth.Accounts.User

  @schema_prefix "auth"
  schema "claims" do
    field(:scope, :string)
    field(:value, :string)

    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  def changeset(%User{} = user, value) do
    {scope, value} = parse(value)

    %Claim{user_id: user.id}
    |> change(scope: scope, value: value)
    |> validate_required([:scope, :value])
    |> validate_format(:scope, ~r/^[a-z][a-z0-9_-]*$/)
    |> validate_format(:value, ~r/^[a-z][a-z0-9_-]*$/)
    |> unique_constraint([:user_id, :scope, :value], message: "has already been granted")
  end

  def by_user_query(%User{} = user) do
    from(c in Claim,
      where: c.user_id == ^user.id,
      order_by: [asc: c.scope, asc: c.value]
    )
  end

  def claim_query(%User{} = user, value) do
    {scope, value} = parse(value)

    from(c in Claim,
      where: c.user_id == ^user.id,
      where: c.scope == ^scope,
      where: c.value == ^value
    )
  end

  defp parse(value) do
    case String.split(value, ":", parts: 2) do
      [scope, claim] -> {scope, claim}
      [claim] -> {"default", claim}
    end
  end
end
