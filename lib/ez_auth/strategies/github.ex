defmodule EzAuth.Strategies.GitHub do
  @moduledoc false

  use EzAuth.Strategy,
    id: :github,
    name: "GitHub",
    identity: :github,
    kind: :social

  import Plug.Conn, only: [get_session: 2, put_session: 3]
  import Phoenix.Controller, only: [redirect: 2]

  alias EzAuth.Accounts
  alias EzAuth.Config
  alias EzAuth.OAuth.GitHub

  @session_state_key :ez_auth_github_state

  @impl true
  def callback(conn, %{"code" => code, "state" => state}) do
    with :ok <- verify_state(conn, state),
         {:ok, profile} <-
           GitHub.fetch_user(
             code,
             Config.github_client_id!(),
             Config.github_client_secret!(),
             callback_url()
           ),
         {:ok, {user, _identity}} <-
           Accounts.find_or_create_social_identity(:github, profile["id"]) do
      {:ok, EzAuth.Auth.sign_in_user(conn, user), user}
    end
  end

  @impl true
  def request(conn, _params) do
    state = random_state()

    conn =
      conn
      |> put_session(@session_state_key, state)
      |> redirect(
        external:
          GitHub.authorization_url(
            Config.github_client_id!(),
            callback_url(),
            state
          )
      )

    {:ok, conn, nil}
  end

  defp callback_url do
    Config.endpoint!().url() <> "/auth/github/callback"
  end

  defp random_state do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp verify_state(conn, state) do
    if get_session(conn, @session_state_key) == state,
      do: :ok,
      else: {:error, :invalid_state}
  end
end
