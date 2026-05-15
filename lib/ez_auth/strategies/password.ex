defmodule EzAuth.Strategies.Password do
  @moduledoc false

  use EzAuth.Strategy,
    id: :password,
    name: "password",
    identity: :email,
    kind: :credential

  alias Ecto.Changeset
  alias EzAuth.Accounts.User

  @impl true
  def request(conn, params) do
    changeset = User.sign_in_with_password_changeset(params)

    with {:ok, _user} <- Changeset.apply_action(changeset, :validate),
         {:ok, email} <- Changeset.fetch_change(changeset, :email),
         {:ok, password} <- Changeset.fetch_change(changeset, :password),
         {:ok, user} <- get_user_by_credentials(email, password) do
      {:ok, EzAuth.Auth.sign_in_user(conn, user), user}
    end
  end

  defp get_user_by_credentials(email, password) do
    email
    |> EzAuth.Accounts.get_user_by_email()
    |> verify_user_password(password)
  end

  defp verify_user_password(%{hashed_password: hash} = user, password)
       when is_binary(hash) and byte_size(password) > 0 do
    if Bcrypt.verify_pass(password, hash),
      do: {:ok, user},
      else: {:error, :invalid_credentials}
  end

  defp verify_user_password(_user, _password) do
    Bcrypt.no_user_verify()
    {:error, :invalid_credentials}
  end
end
