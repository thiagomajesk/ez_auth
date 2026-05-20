defmodule EzAuth.Strategies.EmailOtp do
  @moduledoc false

  use EzAuth.Strategy,
    provider: "email_otp",
    name: "email",
    identity: :email,
    kind: :passwordless,
    callback_methods: [:post]

  alias Ecto.Changeset
  alias EzAuth.Accounts
  alias EzAuth.Accounts.User

  @impl true
  def request(conn, %{"user" => user_params}) do
    changeset = User.sign_in_with_email_changeset(user_params)

    with {:ok, _user} <- Changeset.apply_action(changeset, :validate),
         {:ok, email} <- Changeset.fetch_change(changeset, :email),
         {:ok, {user, identity}} <- Accounts.find_or_create_email_identity(email) do
      Accounts.request_email_verification_code(identity)
      {:ok, conn, user}
    end
  end

  @impl true
  def callback(conn, %{"email" => email, "code" => code}) do
    with {:ok, verification} <- Accounts.verify_code(code, :email, email) do
      {:ok, EzAuth.Auth.sign_in_user(conn, verification.user), verification.user}
    end
  end
end
