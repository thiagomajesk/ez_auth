defmodule EzAuth.OAuth.Shared do
  @moduledoc false

  def fetch_profile(token, user_url, opts) do
    custom_headers = Keyword.get(opts, :headers, [])

    headers =
      [
        {"user-agent", "EzAuth"},
        {"authorization", "Bearer #{token}"}
      ] ++ custom_headers

    case Req.get(user_url, headers: headers) do
      {:ok, response} when response.status in 200..299 ->
        {:ok, response.body}

      {:ok, _response} ->
        {:error, :provider_request_failed}

      error ->
        error
    end
  end

  def request_token(code, token_url, client_id, client_secret, opts) do
    custom_headers = Keyword.get(opts, :headers, [])
    custom_params = Keyword.get(opts, :params, %{})
    redirect_uri = Keyword.fetch!(opts, :redirect_uri)
    token_key = Keyword.get(opts, :token_key, "access_token")

    headers =
      [
        {"user-agent", "EzAuth"},
        {"accept", "application/json"}
      ] ++ custom_headers

    params =
      Map.merge(
        %{
          code: code,
          client_id: client_id,
          client_secret: client_secret,
          redirect_uri: redirect_uri,
          grant_type: "authorization_code"
        },
        custom_params
      )

    case Req.post(token_url, form: params, headers: headers) do
      {:ok, response} when response.status in 200..299 ->
        fetch_token(response.body, token_key)

      {:ok, _response} ->
        {:error, :provider_request_failed}

      error ->
        error
    end
  end

  defp fetch_token(body, token_key) do
    case body do
      %{^token_key => token} -> {:ok, token}
      _body -> {:error, :token_exchange_failed}
    end
  end
end
