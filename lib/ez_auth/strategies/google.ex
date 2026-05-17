defmodule EzAuth.Strategies.Google do
  @moduledoc false

  use EzAuth.Strategy,
    id: :google,
    name: "Google",
    identity: :google,
    kind: :social

  import Plug.Conn, only: [get_session: 2, put_session: 3]
  import Phoenix.Controller, only: [redirect: 2]

  alias EzAuth.Accounts
  alias EzAuth.Config
  alias EzAuth.OAuth.Google

  @session_state_key :ez_auth_google_state

  @impl true
  def callback(conn, %{"code" => code, "state" => state}) do
    with :ok <- verify_state(conn, state),
         {:ok, profile} <-
           Google.fetch_user(
             code,
             Config.google_client_id!(),
             Config.google_client_secret!(),
             callback_url()
           ),
         {:ok, {user, _identity}} <-
           Accounts.find_or_create_social_identity(:google, profile["sub"]) do
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
          Google.authorization_url(
            Config.google_client_id!(),
            callback_url(),
            state
          )
      )

    {:ok, conn, nil}
  end

  defp callback_url do
    Config.endpoint!().url() <> "/auth/google/callback"
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
