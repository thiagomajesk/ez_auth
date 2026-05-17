defmodule EzAuth.OAuth.Google do
  @moduledoc false

  @authorize_url "https://accounts.google.com/o/oauth2/v2/auth"
  @token_url "https://oauth2.googleapis.com/token"
  @userinfo_url "https://openidconnect.googleapis.com/v1/userinfo"

  def authorization_url(client_id, redirect_uri, state) do
    query =
      URI.encode_query(%{
        access_type: "online",
        client_id: client_id,
        redirect_uri: redirect_uri,
        response_type: "code",
        scope: "openid email profile",
        state: state
      })

    @authorize_url <> "?" <> query
  end

  def fetch_user(code, client_id, client_secret, redirect_uri) do
    with {:ok, token} <- fetch_access_token(code, client_id, client_secret, redirect_uri),
         {:ok, %{"sub" => sub} = profile} <- fetch_profile(token) do
      {:ok, Map.put(profile, "sub", to_string(sub))}
    end
  end

  defp fetch_access_token(code, client_id, client_secret, redirect_uri) do
    body =
      URI.encode_query(%{
        client_id: client_id,
        client_secret: client_secret,
        code: code,
        grant_type: "authorization_code",
        redirect_uri: redirect_uri
      })

    headers = [
      {~c"accept", ~c"application/json"},
      {~c"content-type", ~c"application/x-www-form-urlencoded"},
      {~c"user-agent", ~c"EzAuth"}
    ]

    case request(:post, @token_url, headers, body, ~c"application/x-www-form-urlencoded") do
      {:ok, %{"access_token" => token}} -> {:ok, token}
      {:ok, _body} -> {:error, :token_exchange_failed}
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_profile(token) do
    headers = [
      {~c"accept", ~c"application/json"},
      {~c"authorization", ~c"Bearer #{token}"},
      {~c"user-agent", ~c"EzAuth"}
    ]

    request(:get, @userinfo_url, headers)
  end

  defp request(:get, url, headers) do
    case :httpc.request(:get, {String.to_charlist(url), headers}, [], body_format: :binary) do
      {:ok, {{_version, status, _reason}, _headers, body}} when status in 200..299 ->
        Jason.decode(body)

      {:ok, {{_version, _status, _reason}, _headers, _body}} ->
        {:error, :provider_request_failed}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp request(:post, url, headers, body, content_type) do
    request = {String.to_charlist(url), headers, content_type, body}

    case :httpc.request(:post, request, [], body_format: :binary) do
      {:ok, {{_version, status, _reason}, _headers, body}} when status in 200..299 ->
        Jason.decode(body)

      {:ok, {{_version, _status, _reason}, _headers, _body}} ->
        {:error, :provider_request_failed}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
