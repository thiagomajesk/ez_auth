defmodule EzAuth.Strategies.GoogleTest do
  use EzAuth.Test.MoxCase, async: true

  import EzAuth.Test.ConnHelpers
  import EzAuth.TestConfig
  import Phoenix.ConnTest, only: [redirected_to: 1]
  import Plug.Conn

  alias EzAuth.Accounts
  alias EzAuth.Auth
  alias EzAuth.OAuth.Shared, as: OAuth
  alias EzAuth.Strategies.Google

  describe "request/2" do
    test "stores oauth state and redirects to Google" do
      stub_config()

      assert {:ok, conn, nil} = Google.request(build_session_conn(), %{})

      assert state = get_session(conn, :ez_auth_google_state)
      assert redirected_to(conn) =~ "https://accounts.google.com/o/oauth2/v2/auth?"
      assert redirected_to(conn) =~ "client_id=google-client-id"
      assert redirected_to(conn) =~ "state=#{state}"
    end
  end

  describe "callback/2" do
    test "rejects callbacks with invalid state" do
      stub_config()

      assert {:error, :invalid_state} =
               Google.callback(build_session_conn(%{ez_auth_google_state: "expected"}), %{
                 "code" => "code",
                 "state" => "actual"
               })
    end

    test "fetches the provider profile, finds the user, and signs in" do
      stub_config()
      conn = build_session_conn(%{ez_auth_google_state: "state"})
      user = %{id: 1}

      expect(OAuth, :request_token, fn code, token_url, client_id, client_secret, opts ->
        assert code == "code"
        assert token_url == "https://oauth2.googleapis.com/token"
        assert client_id == "google-client-id"
        assert client_secret == "google-client-secret"
        assert opts == [redirect_uri: "http://localhost/auth/google/callback"]

        {:ok, "access-token"}
      end)

      expect(OAuth, :fetch_profile, fn token, user_url, opts ->
        assert token == "access-token"
        assert user_url == "https://openidconnect.googleapis.com/v1/userinfo"
        assert opts == [headers: [{"accept", "application/json"}]]
        {:ok, %{"sub" => 12_345}}
      end)

      expect(Accounts, :find_or_create_social_identity, fn "google", "12345" ->
        {:ok, {user, %{}}}
      end)

      expect(Auth, :sign_in_user, fn ^conn, ^user ->
        assign(conn, :signed_in, true)
      end)

      assert {:ok, %{assigns: %{signed_in: true}}, %{id: 1}} =
               Google.callback(conn, %{"code" => "code", "state" => "state"})
    end
  end
end
