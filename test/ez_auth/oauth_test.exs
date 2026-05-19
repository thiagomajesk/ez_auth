defmodule EzAuth.OAuth.SharedTest do
  use EzAuth.Test.MoxCase, async: true

  alias EzAuth.OAuth.Shared, as: OAuth

  describe "fetch_profile/3" do
    test "fetches the provider profile" do
      expect(Req, :get, fn "https://provider.example/user", opts ->
        assert opts[:headers] == [
                 {"user-agent", "EzAuth"},
                 {"authorization", "Bearer access-token"},
                 {"accept", "application/vnd.provider+json"}
               ]

        {:ok, %Req.Response{status: 200, body: %{"id" => 123}}}
      end)

      assert {:ok, %{"id" => 123}} =
               OAuth.fetch_profile(
                 "access-token",
                 "https://provider.example/user",
                 headers: [{"accept", "application/vnd.provider+json"}]
               )
    end

    test "returns provider request failures" do
      expect(Req, :get, fn "https://provider.example/user", _opts ->
        {:ok, %Req.Response{status: 500, body: %{}}}
      end)

      assert {:error, :provider_request_failed} =
               OAuth.fetch_profile("access-token", "https://provider.example/user", [])
    end
  end

  describe "request_token/5" do
    test "exchanges the code for an access token" do
      expect(Req, :post, fn "https://provider.example/oauth/token", opts ->
        assert opts[:form] == %{
                 client_id: "client-id",
                 client_secret: "client-secret",
                 code: "code",
                 grant_type: "authorization_code",
                 redirect_uri: "https://app.example/auth/provider/callback"
               }

        assert opts[:headers] == [
                 {"user-agent", "EzAuth"},
                 {"accept", "application/json"}
               ]

        {:ok, %Req.Response{status: 200, body: %{"access_token" => "access-token"}}}
      end)

      assert {:ok, "access-token"} =
               OAuth.request_token(
                 "code",
                 "https://provider.example/oauth/token",
                 "client-id",
                 "client-secret",
                 redirect_uri: "https://app.example/auth/provider/callback"
               )
    end

    test "merges custom params and headers" do
      expect(Req, :post, fn "https://provider.example/oauth/token", opts ->
        assert opts[:form] == %{
                 client_id: "client-id",
                 client_secret: "client-secret",
                 code: "code",
                 grant_type: "authorization_code",
                 resource: "provider-resource",
                 redirect_uri: "https://app.example/auth/provider/callback"
               }

        assert opts[:headers] == [
                 {"user-agent", "EzAuth"},
                 {"accept", "application/json"},
                 {"provider-header", "provider-value"}
               ]

        {:ok, %Req.Response{status: 200, body: %{"access_token" => "access-token"}}}
      end)

      assert {:ok, "access-token"} =
               OAuth.request_token(
                 "code",
                 "https://provider.example/oauth/token",
                 "client-id",
                 "client-secret",
                 redirect_uri: "https://app.example/auth/provider/callback",
                 params: %{resource: "provider-resource"},
                 headers: [{"provider-header", "provider-value"}]
               )
    end

    test "returns provider request failures" do
      expect(Req, :post, fn "https://provider.example/oauth/token", _opts ->
        {:ok, %Req.Response{status: 500, body: %{}}}
      end)

      assert {:error, :provider_request_failed} =
               OAuth.request_token(
                 "code",
                 "https://provider.example/oauth/token",
                 "client-id",
                 "client-secret",
                 redirect_uri: "https://app.example/auth/provider/callback"
               )
    end

    test "supports provider-specific token keys" do
      expect(Req, :post, fn "https://provider.example/oauth/token", _opts ->
        {:ok, %Req.Response{status: 200, body: %{"id_token" => "id-token"}}}
      end)

      assert {:ok, "id-token"} =
               OAuth.request_token(
                 "code",
                 "https://provider.example/oauth/token",
                 "client-id",
                 "client-secret",
                 redirect_uri: "https://app.example/auth/provider/callback",
                 token_key: "id_token"
               )
    end

    test "returns token exchange failures" do
      expect(Req, :post, fn "https://provider.example/oauth/token", _opts ->
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      assert {:error, :token_exchange_failed} =
               OAuth.request_token(
                 "code",
                 "https://provider.example/oauth/token",
                 "client-id",
                 "client-secret",
                 redirect_uri: "https://app.example/auth/provider/callback"
               )
    end
  end
end
