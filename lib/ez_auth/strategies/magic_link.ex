defmodule EzAuth.Strategies.MagicLink do
  @moduledoc false

  use EzAuth.Strategy,
    id: :magic_link,
    name: "link",
    identity: :email,
    kind: :passwordless

  alias Ecto.Changeset
  alias EzAuth.Accounts
  alias EzAuth.Accounts.User

  @impl true
  def request(conn, params) do
    changeset = User.sign_in_with_email_changeset(params)

    with {:ok, _} <- Changeset.apply_action(changeset, :validate),
         {:ok, email} <- Changeset.fetch_change(changeset, :email),
         {:ok, {user, identity}} <- Accounts.find_or_create_email_identity(email) do
      Accounts.issue_identity_verification(identity, :email)
      {:ok, conn, user}
    end
  end

  @impl true
  def callback(conn, %{"token" => token}) do
    case Accounts.verify_magic_link(token, :email) do
      {:error, reason} ->
        {:error, reason}

      {:ok, %{user: user}} ->
        {:ok, EzAuth.Auth.sign_in_user(conn, user), user}
    end
  end
end
