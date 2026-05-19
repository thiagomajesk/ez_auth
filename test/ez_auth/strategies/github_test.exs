defmodule EzAuth.Strategies.GitHubTest do
  use EzAuth.Test.MoxCase, async: true

  import EzAuth.Test.ConnHelpers
  import EzAuth.TestConfig
  import Phoenix.ConnTest, only: [redirected_to: 1]
  import Plug.Conn

  alias EzAuth.Accounts
  alias EzAuth.Auth
  alias EzAuth.OAuth.Shared, as: OAuth
  alias EzAuth.Strategies.GitHub

  describe "request/2" do
    test "stores oauth state and redirects to GitHub" do
      stub_config()

      assert {:ok, conn, nil} = GitHub.request(build_session_conn(), %{})

      assert state = get_session(conn, :ez_auth_github_state)
      assert redirected_to(conn) =~ "https://github.com/login/oauth/authorize?"
      assert redirected_to(conn) =~ "client_id=github-client-id"
      assert redirected_to(conn) =~ "state=#{state}"
    end
  end

  describe "callback/2" do
    test "rejects callbacks with invalid state" do
      stub_config()

      assert {:error, :invalid_state} =
               GitHub.callback(build_session_conn(%{ez_auth_github_state: "expected"}), %{
                 "code" => "code",
                 "state" => "actual"
               })
    end

    test "fetches the provider profile, finds the user, and signs in" do
      stub_config()
      conn = build_session_conn(%{ez_auth_github_state: "state"})
      user = %{id: 1}

      expect(OAuth, :request_token, fn code, token_url, client_id, client_secret, opts ->
        assert code == "code"
        assert token_url == "https://github.com/login/oauth/access_token"
        assert client_id == "github-client-id"
        assert client_secret == "github-client-secret"
        assert opts == [redirect_uri: "http://localhost/auth/github/callback"]

        {:ok, "access-token"}
      end)

      expect(OAuth, :fetch_profile, fn token, user_url, opts ->
        assert token == "access-token"
        assert user_url == "https://api.github.com/user"
        assert opts == [headers: [{"accept", "application/vnd.github+json"}]]
        {:ok, %{"id" => 12_345}}
      end)

      expect(Accounts, :find_or_create_social_identity, fn :github, "12345" ->
        {:ok, {user, %{}}}
      end)

      expect(Auth, :sign_in_user, fn ^conn, ^user ->
        assign(conn, :signed_in, true)
      end)

      assert {:ok, %{assigns: %{signed_in: true}}, %{id: 1}} =
               GitHub.callback(conn, %{"code" => "code", "state" => "state"})
    end

    test "returns provider failures" do
      stub_config()
      conn = build_session_conn(%{ez_auth_github_state: "state"})

      expect(OAuth, :request_token, fn code, token_url, client_id, client_secret, opts ->
        assert code == "code"
        assert token_url == "https://github.com/login/oauth/access_token"
        assert client_id == "github-client-id"
        assert client_secret == "github-client-secret"
        assert opts == [redirect_uri: "http://localhost/auth/github/callback"]

        {:error, :provider_request_failed}
      end)

      assert {:error, :provider_request_failed} =
               GitHub.callback(conn, %{"code" => "code", "state" => "state"})
    end
  end
end
