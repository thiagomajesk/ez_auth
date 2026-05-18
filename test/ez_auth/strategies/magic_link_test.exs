defmodule EzAuth.Strategies.MagicLinkTest do
  use EzAuth.Test.MoxCase, async: true

  import EzAuth.Test.ConnHelpers
  import EzAuth.TestConfig

  alias EzAuth.Accounts
  alias EzAuth.Auth
  alias EzAuth.Strategies.MagicLink

  describe "request/2 and callback/2" do
    test "requests a magic link, signing up the user on demand if needed" do
      stub_config()
      conn = build_session_conn()
      user = %{id: 1}
      identity = %EzAuth.Accounts.Identity{type: :email, value: "user@example.com", user: user}

      expect(Accounts, :find_or_create_email_identity, fn "user@example.com" ->
        {:ok, {user, identity}}
      end)

      expect(Accounts, :request_email_verification_link, fn ^identity -> :ok end)

      assert {:ok, ^conn, %{id: 1}} =
               MagicLink.request(conn, %{"user" => %{"email" => "user@example.com"}})
    end

    test "verifies the token and signs the user in" do
      stub_config()
      conn = build_session_conn()
      user = %{id: 1}

      expect(Accounts, :verify_link, fn "token", :email ->
        {:ok, %{user: user}}
      end)

      expect(Auth, :sign_in_user, fn ^conn, ^user ->
        Plug.Conn.assign(conn, :signed_in, true)
      end)

      assert {:ok, %{assigns: %{signed_in: true}}, %{id: 1}} =
               MagicLink.callback(conn, %{"token" => "token"})
    end

    test "returns the verification failure reason" do
      stub_config()
      conn = build_session_conn()

      expect(Accounts, :verify_link, fn "token", :email ->
        {:error, :invalid_token}
      end)

      assert {:error, :invalid_token} =
               MagicLink.callback(conn, %{"token" => "token"})
    end
  end
end
