defmodule EzAuth.Accounts.UserClaim do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias __MODULE__
  alias EzAuth.Accounts.User

  @schema_prefix "auth"
  schema "user_claims" do
    field(:claim, :string)

    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  def by_user_query(%User{} = user) do
    from(c in UserClaim,
      where: c.user_id == ^user.id,
      order_by: [asc: c.claim]
    )
  end

  def changeset(%User{} = user, claim) do
    %UserClaim{user_id: user.id}
    |> change(claim: claim)
    |> validate_required([:claim])
    |> unique_constraint([:user_id, :claim], message: "has already been granted")
  end

  def user_claim_query(%User{} = user, claim) do
    from(c in UserClaim,
      where: c.user_id == ^user.id,
      where: c.claim == ^claim
    )
  end
end
