defmodule EzAuth.Accounts.Identity do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias __MODULE__
  alias EzAuth.Accounts.User

  @types [
    :email,
    :phone,
    :google,
    :github,
    :apple,
    :microsoft,
    :discord,
    :saml
  ]

  @schema_prefix "auth"
  schema "identities" do
    field(:type, Ecto.Enum, values: @types)
    field(:value, :string)
    field(:verified_at, :utc_datetime)

    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  def changeset(%User{} = user, type, value) do
    %Identity{user_id: user.id}
    |> change(type: type, value: value)
    |> unique_constraint([:type, :value], message: "has already been taken")
  end

  def update_verified_at_query(%User{} = user, type, value) do
    now = DateTime.utc_now(:second)

    already_claimed =
      from(o in Identity,
        where: o.type == ^type,
        where: o.value == ^value,
        where: o.user_id != ^user.id,
        where: not is_nil(o.verified_at)
      )

    from(i in Identity,
      where: i.user_id == ^user.id,
      where: i.type == ^type,
      where: i.value == ^value,
      where: not exists(subquery(already_claimed)),
      update: [set: [verified_at: coalesce(i.verified_at, ^now)]]
    )
  end

  def verified_by_type_and_value_query(type, value) do
    from(i in Identity,
      where: i.type == ^type,
      where: i.value == ^value,
      where: not is_nil(i.verified_at)
    )
  end

  @doc """
  Detects which identity (`:email | :phone | nil`) a typed value looks like,
  restricted to the `accepts` list. Naive shape match for UX feedback only.
  """
  def detect_identity(value, accepts) when is_binary(value) do
    patterns = %{email: ~r/@/, phone: ~r/^[+\d]/}

    Enum.find_value(accepts, fn identity ->
      pattern = patterns[identity]
      if pattern && value =~ pattern, do: identity
    end)
  end
end
