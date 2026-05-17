defmodule EzAuth.AuthTest do
  use EzAuth.Test.MoxCase, async: true

  import EzAuth.TestConfig
  import Plug.Conn
  import Phoenix.ConnTest

  alias EzAuth.Accounts
  alias EzAuth.Auth
  alias EzAuth.Scopes.UserScope
  alias EzAuth.Test.Endpoint

  describe "fetch_current_scope/1" do
    test "assigns the current scope when the session token is valid" do
      user = %{id: 1}

      expect(Accounts, :get_user_by_session_token, fn "token" -> user end)

      conn =
        build_conn()
        |> init_test_session(%{user_token: "token"})
        |> Auth.fetch_current_scope()

      assert %UserScope{user: ^user} = conn.assigns.current_scope
    end

    test "assigns nil without clearing the session when token decoding fails" do
      expect(Accounts, :get_user_by_session_token, fn "bad-token" -> :error end)

      conn =
        build_conn()
        |> init_test_session(%{user_token: "bad-token"})
        |> Auth.fetch_current_scope()

      refute conn.assigns.current_scope
      assert get_session(conn, :user_token) == "bad-token"
    end

    test "assigns nil without clearing the session when the token no longer maps to a user" do
      expect(Accounts, :get_user_by_session_token, fn "stale-token" -> nil end)

      conn =
        build_conn()
        |> init_test_session(%{user_token: "stale-token"})
        |> put_session(:foo, "bar")
        |> Auth.fetch_current_scope()

      refute conn.assigns.current_scope
      assert get_session(conn, :user_token) == "stale-token"
      assert get_session(conn, :foo) == "bar"
    end
  end

  describe "redirect_if_authenticated/1" do
    test "halts and redirects authenticated users" do
      conn =
        build_conn()
        |> assign(:current_scope, UserScope.new(%{id: 1}))
        |> Auth.redirect_if_authenticated()

      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "returns the connection when there is no authenticated user" do
      conn =
        build_conn()
        |> assign(:current_scope, nil)
        |> Auth.redirect_if_authenticated()

      refute conn.halted
    end
  end

  describe "disconnect_sessions/2" do
    test "broadcasts disconnect for each revoked session" do
      raw_token_1 = :crypto.strong_rand_bytes(32)
      raw_token_2 = :crypto.strong_rand_bytes(32)
      topic_1 = "auth_sessions:" <> Base.url_encode64(raw_token_1, padding: false)
      topic_2 = "auth_sessions:" <> Base.url_encode64(raw_token_2, padding: false)

      expect(Endpoint, :broadcast, fn ^topic_1, "disconnect", _payload -> :ok end)
      expect(Endpoint, :broadcast, fn ^topic_2, "disconnect", _payload -> :ok end)

      assert :ok = Auth.disconnect_sessions(Endpoint, [raw_token_1, raw_token_2])
    end
  end

  describe "require_authenticated/1" do
    test "halts and stores the return path for unauthenticated GET requests" do
      conn = build_conn(:get, "/settings")
      conn = init_test_session(conn, %{})
      conn = Phoenix.Controller.fetch_flash(conn, [])
      conn = assign(conn, :current_scope, nil)
      conn = Auth.require_authenticated(conn)

      assert conn.halted
      assert redirected_to(conn) == "/sign-in"
      assert get_session(conn, :return_to) == "/settings"
    end

    test "does not overwrite the return path for non-GET requests" do
      conn = build_conn(:post, "/settings")
      conn = init_test_session(conn, %{})
      conn = Phoenix.Controller.fetch_flash(conn, [])
      conn = assign(conn, :current_scope, nil)
      conn = Auth.require_authenticated(conn)

      assert conn.halted
      assert redirected_to(conn) == "/sign-in"
      refute get_session(conn, :return_to)
    end

    test "returns the connection when the user is authenticated" do
      conn =
        build_conn()
        |> assign(:current_scope, UserScope.new(%{id: 1}))
        |> Auth.require_authenticated()

      refute conn.halted
    end
  end

  describe "sign_in_user/2" do
    test "renews the session, stores the token state, and redirects" do
      stub_config(after_sign_in_path: "/dashboard")
      expect(Accounts, :generate_user_session_token, fn %{id: 1} -> "token" end)

      conn =
        build_conn()
        |> init_test_session(%{foo: "bar"})
        |> Auth.sign_in_user(%{id: 1})

      assert get_session(conn, :user_token) == "token"
      assert get_session(conn, :live_socket_id) == "auth_sessions:token"
      assert redirected_to(conn) == "/dashboard"
      refute get_session(conn, :foo)
    end

    test "redirects to the stored return path" do
      stub_config(after_sign_in_path: "/dashboard")
      expect(Accounts, :generate_user_session_token, fn %{id: 1} -> "token" end)

      conn =
        build_conn()
        |> init_test_session(%{return_to: "/battles"})
        |> Auth.sign_in_user(%{id: 1})

      assert get_session(conn, :user_token) == "token"
      assert get_session(conn, :live_socket_id) == "auth_sessions:token"
      assert redirected_to(conn) == "/battles"
      refute get_session(conn, :return_to)
    end
  end

  describe "sign_out_user/2" do
    test "redirects when no session token is present" do
      stub_config()
      expect(Accounts, :revoke_user_session_token, fn nil -> :noop end)

      conn =
        build_conn()
        |> init_test_session(%{foo: "bar"})
        |> put_endpoint()
        |> Auth.sign_out_user(%{id: 1})

      assert get_session(conn, :foo) == "bar"
      assert redirected_to(conn) == "/sign-in"
    end

    test "renews the session and redirects when the token is invalid" do
      stub_config()
      expect(Accounts, :revoke_user_session_token, fn "bad-token" -> :error end)

      conn =
        build_conn()
        |> init_test_session(%{user_token: "bad-token", foo: "bar"})
        |> put_endpoint()
        |> Auth.sign_out_user(%{id: 1})

      assert redirected_to(conn) == "/sign-in"
      refute get_session(conn, :user_token)
      refute get_session(conn, :foo)
    end

    test "broadcasts disconnect before renewing the session" do
      stub_config()
      raw_token = :crypto.strong_rand_bytes(32)
      topic = "auth_sessions:" <> Base.url_encode64(raw_token, padding: false)

      expect(Endpoint, :broadcast, fn ^topic, "disconnect", _payload -> :ok end)
      expect(Accounts, :revoke_user_session_token, fn "token" -> {1, [raw_token]} end)

      conn =
        build_conn()
        |> init_test_session(%{user_token: "token", live_socket_id: "auth_sessions:token"})
        |> put_endpoint()
        |> Auth.sign_out_user(%{id: 1})

      assert redirected_to(conn) == "/sign-in"
      refute get_session(conn, :user_token)
      refute get_session(conn, :live_socket_id)
    end
  end

  defp put_endpoint(conn), do: put_private(conn, :phoenix_endpoint, Endpoint)
end
