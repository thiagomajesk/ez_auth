defmodule EzAuth.Strategies.EmailOtp do
  @moduledoc false

  use EzAuth.Strategy,
    id: :email_otp,
    name: "email",
    identity: :email,
    kind: :passwordless,
    callback_methods: [:post]

  alias Ecto.Changeset
  alias EzAuth.Accounts
  alias EzAuth.Accounts.User

  @impl true
  def callback(conn, %{"user" => user_params}) do
    changeset = User.sign_in_with_email_code_changeset(user_params)

    with {:ok, _user} <- Changeset.apply_action(changeset, :validate),
         {:ok, email} <- Changeset.fetch_change(changeset, :email),
         {:ok, code} <- Changeset.fetch_change(changeset, :code),
         {:ok, verification} <- Accounts.verify_email_otp(code, email) do
      {:ok, EzAuth.Auth.sign_in_user(conn, verification.user), verification.user}
    end
  end

  @impl true
  def request(conn, %{"user" => user_params}) do
    changeset = User.sign_in_with_email_changeset(user_params)

    with {:ok, _user} <- Changeset.apply_action(changeset, :validate),
         {:ok, email} <- Changeset.fetch_change(changeset, :email),
         {:ok, {user, identity}} <- Accounts.find_or_create_email_identity(email) do
      Accounts.request_email_otp(identity)
      {:ok, conn, user}
    end
  end
end
