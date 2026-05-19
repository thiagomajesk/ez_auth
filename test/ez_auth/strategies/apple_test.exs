defmodule EzAuth.Strategies.AppleTest do
  use EzAuth.Test.MoxCase, async: true

  import EzAuth.Test.ConnHelpers
  import EzAuth.TestConfig
  import Phoenix.ConnTest, only: [redirected_to: 1]
  import Plug.Conn

  alias EzAuth.Accounts
  alias EzAuth.Auth
  alias EzAuth.OAuth.Shared, as: OAuth
  alias EzAuth.OAuth.Apple
  alias EzAuth.Strategies.Apple, as: AppleStrategy

  test "uses a post callback for form_post submissions" do
    assert AppleStrategy.__meta__(:callback_methods) == [:post]
  end

  describe "request/2" do
    test "stores oauth state and redirects to Apple" do
      stub_config()

      assert {:ok, conn, nil} = AppleStrategy.request(build_session_conn(), %{})

      assert state = get_session(conn, :ez_auth_apple_state)
      assert redirected_to(conn) =~ "https://appleid.apple.com/auth/authorize?"
      assert redirected_to(conn) =~ "client_id=apple-client-id"
      assert redirected_to(conn) =~ "state=#{state}"
    end
  end

  describe "callback/2" do
    test "rejects callbacks with invalid state" do
      stub_config()

      assert {:error, :invalid_state} =
               AppleStrategy.callback(build_session_conn(%{ez_auth_apple_state: "expected"}), %{
                 "code" => "code",
                 "state" => "actual"
               })
    end

    test "fetches the provider profile, finds the user, and signs in" do
      stub_config()
      conn = build_session_conn(%{ez_auth_apple_state: "state"})
      user = %{id: 1}

      expect(Apple, :client_secret, fn "apple-client-id",
                                       "apple-team-id",
                                       "apple-key-id",
                                       _private_key ->
        "client-secret"
      end)

      expect(OAuth, :request_token, fn code, token_url, client_id, client_secret, opts ->
        assert code == "code"
        assert token_url == "https://appleid.apple.com/auth/token"
        assert client_id == "apple-client-id"
        assert client_secret == "client-secret"

        assert opts == [
                 redirect_uri: "http://localhost/auth/apple/callback",
                 token_key: "id_token"
               ]

        {:ok, "id-token"}
      end)

      expect(Apple, :verify_id_token, fn "id-token", "apple-client-id" ->
        {:ok, %{"sub" => 12_345}}
      end)

      expect(Accounts, :find_or_create_social_identity, fn :apple, "12345" ->
        {:ok, {user, %{}}}
      end)

      expect(Auth, :sign_in_user, fn ^conn, ^user ->
        assign(conn, :signed_in, true)
      end)

      assert {:ok, %{assigns: %{signed_in: true}}, %{id: 1}} =
               AppleStrategy.callback(conn, %{"code" => "code", "state" => "state"})
    end
  end
end
