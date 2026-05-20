defmodule EzAuth.Auth do
  @moduledoc """
  Web-facing authentication helpers.
  """

  import Plug.Conn
  import Phoenix.Controller
  import EzAuth.Translations, only: [translate: 1]

  alias EzAuth.Config
  alias EzAuth.Scopes.UserScope

  def fetch_current_scope(conn, _opts \\ []) do
    token = get_session(conn, :user_token)

    case EzAuth.Accounts.get_user_by_session_token(token) do
      :error ->
        assign(conn, :current_scope, nil)

      nil ->
        assign(conn, :current_scope, nil)

      user ->
        claims = EzAuth.Accounts.list_claims(user)
        assign(conn, :current_scope, UserScope.new(user, claims))
    end
  end

  def require_authenticated(conn, _opts \\ []) do
    if get_in(conn.assigns.current_scope.user) do
      conn
    else
      conn
      |> put_flash(:error, translate("You must log in to access this page."))
      |> maybe_store_return_to()
      |> redirect(to: Config.sign_in_path())
      |> halt()
    end
  end

  def redirect_if_authenticated(conn) do
    if get_in(conn.assigns.current_scope.user) do
      conn
      |> redirect(to: Config.after_sign_in_path())
      |> halt()
    else
      conn
    end
  end

  def disconnect_sessions(endpoint, tokens) do
    Enum.each(tokens, fn raw_token ->
      topic = "auth_sessions:" <> Base.url_encode64(raw_token, padding: false)
      endpoint.broadcast(topic, "disconnect", %{})
    end)
  end

  def sign_in_user(conn, user) do
    token = EzAuth.Accounts.generate_user_session_token(user)
    live_socket_id = "auth_sessions:" <> token

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, live_socket_id)
    |> redirect(to: after_sign_in_path(conn))
  end

  def sign_out_user(conn, _user) do
    endpoint = conn.private.phoenix_endpoint
    token = get_session(conn, :user_token)

    case EzAuth.Accounts.revoke_user_session_token(token) do
      :noop ->
        redirect(conn, to: Config.sign_in_path())

      :error ->
        conn
        |> renew_session()
        |> redirect(to: Config.sign_in_path())

      {_count, tokens} ->
        disconnect_sessions(endpoint, tokens)

        conn
        |> renew_session()
        |> redirect(to: Config.sign_in_path())
    end
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp maybe_store_return_to(conn) do
    if conn.method == "GET",
      do: put_session(conn, :return_to, current_path(conn)),
      else: conn
  end

  defp after_sign_in_path(conn) do
    return_to = get_session(conn, :return_to)
    return_to || Config.after_sign_in_path()
  end
end
