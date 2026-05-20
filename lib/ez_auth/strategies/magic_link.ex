defmodule EzAuth.Strategies.MagicLink do
  @moduledoc false

  use EzAuth.Strategy,
    provider: "magic_link",
    name: "link",
    identity: :email,
    kind: :passwordless

  alias Ecto.Changeset
  alias EzAuth.Accounts
  alias EzAuth.Accounts.User

  @impl true
  def request(conn, %{"user" => user_params}) do
    changeset = User.sign_in_with_email_changeset(user_params)

    with {:ok, _user} <- Changeset.apply_action(changeset, :validate),
         {:ok, email} <- Changeset.fetch_change(changeset, :email),
         {:ok, {user, identity}} <- Accounts.find_or_create_email_identity(email) do
      Accounts.request_email_verification_link(identity)
      {:ok, conn, user}
    end
  end

  @impl true
  def callback(conn, %{"token" => token}) do
    case Accounts.verify_link(token, :email) do
      {:error, reason} ->
        {:error, reason}

      {:ok, %{user: user}} ->
        {:ok, EzAuth.Auth.sign_in_user(conn, user), user}
    end
  end
end
