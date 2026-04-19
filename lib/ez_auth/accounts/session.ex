defmodule EzAuth.Accounts.Session do
  use Ecto.Schema

  import Ecto.Query

  alias __MODULE__
  alias EzAuth.Accounts.Token
  alias EzAuth.Accounts.User

  @schema_prefix "auth"
  schema "sessions" do
    field(:token, :binary)
    field(:expires_at, :utc_datetime)

    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  def build_session_token(%User{} = user) do
    token = Token.build_session()

    {token.encoded_token,
     %Session{user_id: user.id, token: token.raw_token, expires_at: token.expires_at}}
  end

  def by_token_query(token) do
    from(s in Session, where: s.token == ^token, select: s.token)
  end

  def by_user_query(%User{} = user) do
    from(s in Session, where: s.user_id == ^user.id, select: s.token)
  end

  def verify_session_token_query(token) do
    now = DateTime.utc_now(:second)

    from(s in Session,
      join: u in User,
      on: u.id == s.user_id,
      where: s.token == ^token,
      where: s.expires_at > ^now,
      select: u
    )
  end
end
