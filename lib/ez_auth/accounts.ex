defmodule EzAuth.Accounts do
  @moduledoc """
  Public authentication operations for users, identities, sessions, and verifications.
  """

  import Ecto.Query

  alias EzAuth.Accounts.Identity
  alias EzAuth.Accounts.Session
  alias EzAuth.Accounts.Token
  alias EzAuth.Accounts.User
  alias EzAuth.Accounts.Verification
  alias EzAuth.Config
  alias EzAuth.Sender

  @doc """
  Creates a user from email + password sign-up attributes.
  """
  def create_user_with_password(attrs) do
    changeset = User.sign_up_changeset(attrs)

    Config.repo!().transact(fn ->
      with {:ok, user} <- Config.repo!().insert(changeset),
           {:ok, email} <- Ecto.Changeset.fetch_change(changeset, :email),
           {:ok, identity} <- create_identity(user, :email, email),
           do: {:ok, {user, %{identity | user: user}}}
    end)
  end

  @doc """
  Creates a passwordless user with an email identity (used by magic-link / email-OTP request flows).
  """
  def create_user_with_email(email) do
    Config.repo!().transact(fn ->
      with {:ok, user} <- Config.repo!().insert(%User{}),
           {:ok, identity} <- create_identity(user, :email, email),
           do: {:ok, {user, %{identity | user: user}}}
    end)
  end

  @doc """
  Creates a passwordless user with a phone identity (used by SMS OTP request flow).
  """
  def create_user_with_phone(phone) do
    Config.repo!().transact(fn ->
      with {:ok, user} <- Config.repo!().insert(%User{}),
           {:ok, identity} <- create_identity(user, :phone, phone),
           do: {:ok, {user, %{identity | user: user}}}
    end)
  end

  @doc """
  Returns the user and verified email identity, creating a passwordless user when none exists.
  """
  def find_or_create_email_identity(value) do
    with {:error, :not_found} <- get_verified_identity(:email, value),
         do: create_user_with_email(value)
  end

  @doc """
  Returns the user and verified phone identity, creating a passwordless user when none exists.
  """
  def find_or_create_phone_identity(value) do
    with {:error, :not_found} <- get_verified_identity(:phone, value),
         do: create_user_with_phone(value)
  end

  @doc """
  Returns the user and verified social identity, creating them when none exists.
  """
  def find_or_create_social_identity(type, value) do
    with {:error, :not_found} <- get_verified_identity(type, value),
         do: create_user_with_social_identity(type, value)
  end

  @doc """
  Generates a session token for the user.
  """
  def generate_user_session_token(%User{} = user) do
    {token, session} = Session.build_session_token(user)
    Config.repo!().insert!(session)
    token
  end

  def get_user_by_email(email) do
    Config.repo!().one(User.by_identity_query(:email, email))
  end

  def get_user_by_username(username) do
    Config.repo!().one(User.by_username_query(username))
  end

  @doc """
  Fetches the user for a valid session token.
  """
  def get_user_by_session_token(nil), do: nil

  def get_user_by_session_token(token) do
    with {:ok, raw_token} <- Base.url_decode64(token, padding: false) do
      Config.repo!().one(Session.verify_session_token_query(raw_token))
    end
  end

  @doc """
  Fetches a verified identity by type and value, returning the user it belongs to alongside.
  """
  def get_verified_identity(type, value) do
    query =
      from(i in Identity,
        where: i.type == ^type,
        where: i.value == ^value,
        where: not is_nil(i.verified_at),
        preload: :user
      )

    case Config.repo!().one(query) do
      nil -> {:error, :not_found}
      identity -> {:ok, {identity.user, identity}}
    end
  end

  def email_taken?(email) do
    Config.repo!().exists?(Identity.verified_by_type_and_value_query(:email, email))
  end

  def username_taken?(username) do
    Config.repo!().exists?(User.by_username_query(username))
  end

  @doc """
  Issues an email verification link for the given identity.
  """
  def request_email_verification_link(%Identity{} = identity) do
    token =
      Token.build_verification_token(
        format: :random,
        size: Config.token_rand_size(),
        validity: Config.magic_link_validity_in_minutes()
      )

    insert_verification(identity.user, :email, identity.value, token)

    Sender.maybe_invoke(Config.sender(), :email, {identity.user, token})
  end

  @doc """
  Issues an email verification code for the given identity.
  """
  def request_email_verification_code(%Identity{} = identity) do
    token =
      Token.build_verification_token(
        format: :code,
        size: Config.recovery_code_length(),
        validity: Config.recovery_code_validity_in_minutes()
      )

    insert_verification(identity.user, :email, identity.value, token)

    Sender.maybe_invoke(Config.sender(), :email, {identity.user, token})
  end

  @doc """
  Issues a phone verification code for the given identity.
  """
  def request_phone_verification_code(%Identity{} = identity) do
    token =
      Token.build_verification_token(
        format: :code,
        size: Config.recovery_code_length(),
        validity: Config.recovery_code_validity_in_minutes()
      )

    insert_verification(identity.user, :phone, identity.value, token)

    Sender.maybe_invoke(Config.sender(), :sms_otp, {identity.user, token})
  end

  @doc """
  Issues a recovery code and dispatches it via the configured sender.

  Returns `:ok` even when the email is unknown, so callers cannot probe for account existence.
  """
  def request_password_recovery(email) do
    case get_user_by_email(email) do
      nil ->
        :ok

      user ->
        token =
          Token.build_verification_token(
            format: :code,
            size: Config.recovery_code_length(),
            validity: Config.recovery_code_validity_in_minutes()
          )

        insert_verification(user, :recovery, email, token)

        Sender.maybe_invoke(Config.sender(), :recovery, {user, token})
    end
  end

  @doc """
  Revokes a single session token.
  """
  def revoke_user_session_token(nil), do: :noop

  def revoke_user_session_token(token) do
    with {:ok, raw_token} <- Base.url_decode64(token, padding: false) do
      Config.repo!().delete_all(Session.by_token_query(raw_token))
    end
  end

  @doc """
  Revokes all session tokens for a user.
  """
  def revoke_user_sessions(%User{} = user) do
    Config.repo!().delete_all(Session.by_user_query(user))
  end

  @doc """
  Updates the user's profile fields (name, username, metadata).
  """
  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Config.repo!().update()
  end

  @doc """
  Verifies a user link token and consumes it.

  The token is the long random secret embedded in a URL. Used by `:email`
  identity verification (post-signup confirm and magic-link sign-in) and
  similar link-style flows.
  """
  def verify_link(token, type) do
    with {:ok, query} <- Verification.fetch_by_token_query(token, type),
         do: consume_verification(Config.repo!().one(query))
  end

  @doc """
  Verifies a short user code and consumes it.

  The code is the human-typeable secret sent out-of-band (recovery email,
  SMS OTP). Because the code's entropy is low, the lookup is value-scoped
  to the identity it was issued for when the caller passes a value.
  """
  def verify_code(code, type, value) do
    with {:ok, query} <- Verification.fetch_by_token_query(code, type, value),
         do: consume_verification(Config.repo!().one(query))
  end

  defp create_identity(%User{} = user, type, value) do
    user
    |> Identity.changeset(type, value)
    |> Config.repo!().insert()
  end

  defp create_user_with_social_identity(type, value) do
    Config.repo!().transact(fn ->
      with {:ok, user} <- Config.repo!().insert(%User{}),
           {:ok, identity} <- create_verified_identity(user, type, value),
           do: {:ok, {user, %{identity | user: user}}}
    end)
  end

  defp create_verified_identity(%User{} = user, type, value) do
    user
    |> Identity.changeset(type, value)
    |> Ecto.Changeset.change(verified_at: DateTime.utc_now(:second))
    |> Config.repo!().insert()
  end

  defp insert_verification(user, type, value, token) do
    insert_verification(Verification.build_verification(user, type, value, token))
  end

  defp insert_verification({token, verification}) do
    {token,
     Config.repo!().insert!(
       verification,
       conflict_target: [:user_id, :type, :value],
       on_conflict: {:replace, [:token, :expires_at, :inserted_at]}
     )}
  end

  defp consume_verification(nil), do: {:error, :invalid_token}

  defp consume_verification(%Verification{type: type} = verification)
       when type not in [:email, :phone],
       do: {:ok, Config.repo!().delete!(verification)}

  defp consume_verification(%Verification{} = verification) do
    %{user: user, type: type, value: value} = verification
    query = Identity.update_verified_at_query(user, type, value)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.update_all(:verify, query, [])
      |> Ecto.Multi.delete(:delete, verification, allow_stale: true)

    case Config.repo!().transact(multi) do
      {:ok, %{verify: {0, _rows}}} ->
        {:error, :already_claimed}

      {:ok, %{verify: _result} = changes} ->
        {:ok, Map.fetch!(changes, :delete)}
    end
  end
end
