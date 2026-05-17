defmodule EzAuth.OAuth.GitHub do
  @moduledoc false

  @authorize_url "https://github.com/login/oauth/authorize"
  @token_url "https://github.com/login/oauth/access_token"
  @user_url "https://api.github.com/user"

  def authorization_url(client_id, redirect_uri, state) do
    query =
      URI.encode_query(%{
        client_id: client_id,
        redirect_uri: redirect_uri,
        scope: "read:user user:email",
        state: state
      })

    @authorize_url <> "?" <> query
  end

  def fetch_user(code, client_id, client_secret, redirect_uri) do
    with {:ok, token} <- fetch_access_token(code, client_id, client_secret, redirect_uri),
         {:ok, %{"id" => id} = profile} <- fetch_profile(token) do
      {:ok, Map.put(profile, "id", to_string(id))}
    end
  end

  defp fetch_access_token(code, client_id, client_secret, redirect_uri) do
    body =
      Jason.encode!(%{
        client_id: client_id,
        client_secret: client_secret,
        code: code,
        redirect_uri: redirect_uri
      })

    headers = [
      {~c"accept", ~c"application/json"},
      {~c"content-type", ~c"application/json"},
      {~c"user-agent", ~c"EzAuth"}
    ]

    case request(:post, @token_url, headers, body) do
      {:ok, %{"access_token" => token}} -> {:ok, token}
      {:ok, _body} -> {:error, :token_exchange_failed}
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_profile(token) do
    headers = [
      {~c"accept", ~c"application/vnd.github+json"},
      {~c"authorization", ~c"Bearer #{token}"},
      {~c"user-agent", ~c"EzAuth"}
    ]

    request(:get, @user_url, headers)
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

  defp request(:post, url, headers, body) do
    request = {String.to_charlist(url), headers, ~c"application/json", body}

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
