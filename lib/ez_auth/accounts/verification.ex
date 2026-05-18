defmodule EzAuth.Accounts.Verification do
  use Ecto.Schema

  import Ecto.Query

  alias __MODULE__
  alias EzAuth.Accounts.User

  @types [
    :email,
    :phone,
    :recovery,
    :email_change,
    :phone_change
  ]

  @schema_prefix "auth"
  schema "verifications" do
    field(:type, Ecto.Enum, values: @types)

    field(:token, :string)
    field(:value, :string)
    field(:expires_at, :utc_datetime)

    belongs_to(:user, User)

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def build_verification(user, type, value, token) do
    hashed_token = Base.encode64(:crypto.hash(:sha256, token.raw_token))

    {token.encoded_token,
     %Verification{
       type: type,
       value: value,
       user_id: user.id,
       expires_at: token.expires_at,
       token: hashed_token
     }}
  end

  @doc """
  Builds a query for fetching a verification by encoded token when it is still valid.

  Pass `value` to scope the lookup to a specific identity (the email or phone
  the verification was issued for). Required for short codes where the token
  alone isn't enough to bind the lookup to one user; long random tokens can
  omit it.
  """
  def fetch_by_token_query(encoded_token, type, value \\ nil) do
    case Base.url_decode64(encoded_token, padding: false) do
      {:ok, raw_token} ->
        now = DateTime.utc_now(:second)
        hashed_token = Base.encode64(:crypto.hash(:sha256, raw_token))

        query =
          from(v in Verification,
            where: v.type == ^type,
            where: v.expires_at > ^now,
            where: v.token == ^hashed_token,
            preload: [:user]
          )

        {:ok, scope_by_value(query, value)}

      :error ->
        {:error, :invalid_token}
    end
  end

  defp scope_by_value(query, nil), do: query
  defp scope_by_value(query, value), do: where(query, [v], v.value == ^value)
end
