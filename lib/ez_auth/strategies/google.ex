defmodule EzAuth.Strategies.Google do
  @moduledoc false

  use EzAuth.OAuth,
    provider: "google",
    name: "Google",
    user_url: "https://openidconnect.googleapis.com/v1/userinfo",
    authorize_url: "https://accounts.google.com/o/oauth2/v2/auth",
    token_url: "https://oauth2.googleapis.com/token",
    headers: [{"accept", "application/json"}]

  alias EzAuth.Config
  alias EzAuth.OAuth.Shared

  @impl true
  def authorization_query(state) do
    URI.encode_query(%{
      state: state,
      client_id: client_id(),
      redirect_uri: callback_url(),
      response_type: "code",
      scope: "openid email profile",
      access_type: "online"
    })
  end

  @impl true
  def client_id, do: Config.google_client_id!()

  @impl true
  def client_secret, do: Config.google_client_secret!()

  @impl true
  def fetch_identity(code) do
    with {:ok, token} <- request_token(code),
         {:ok, profile} <- Shared.fetch_profile(token, @oauth_user_url, headers: @oauth_headers) do
      {:ok, to_string(profile["sub"])}
    end
  end
end
