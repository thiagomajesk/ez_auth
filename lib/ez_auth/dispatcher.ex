defmodule EzAuth.Dispatcher do
  @moduledoc false

  use Phoenix.Controller, formats: []

  import Plug.Conn

  alias EzAuth.Config
  alias EzAuth.Handler

  plug(:check_strategy when action in [:request, :callback])

  def request(conn, %{"user" => user_params}), do: dispatch(conn, user_params, :request)

  def callback(conn, %{"user" => user_params}), do: dispatch(conn, user_params, :callback)

  defp dispatch(conn, params, action) do
    %{strategy: strategy, handler: handler} = conn.private.ez_auth

    case apply(strategy, action, [conn, params]) do
      {:ok, conn, user} ->
        Handler.maybe_invoke(conn, handler, :handle_success, [action, user])

      {:error, reason} ->
        Handler.maybe_invoke(conn, handler, :handle_failure, [action, reason])
    end
  end

  def sign_up(conn, %{"user" => user_params}) do
    %{handler: handler} = conn.private.ez_auth

    case EzAuth.Accounts.create_user_with_password(user_params) do
      {:ok, {user, identity}} ->
        EzAuth.Accounts.request_email_verification(identity)
        Handler.maybe_invoke(conn, handler, :handle_success, [:sign_up, user])

      {:error, reason} ->
        Handler.maybe_invoke(conn, handler, :handle_failure, [:sign_up, reason])
    end
  end

  def sign_out(conn, _params) do
    %{handler: handler} = conn.private.ez_auth
    user = get_in(conn.assigns.current_scope.user)

    conn = EzAuth.Auth.sign_out_user(conn, user)
    Handler.maybe_invoke(conn, handler, :handle_success, [:sign_out, user])
  end

  defp check_strategy(conn, _opts) do
    %{strategy: strategy} = conn.private.ez_auth

    if Config.strategy_enabled?(strategy), do: conn, else: halt(send_resp(conn, 501, ""))
  end
end
