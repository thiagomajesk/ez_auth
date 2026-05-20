defmodule EzAuth.Strategies.Microsoft do
  @moduledoc false

  use EzAuth.OAuth,
    provider: "microsoft",
    name: "Microsoft",
    user_url: "https://graph.microsoft.com/v1.0/me",
    authorize_url: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
    token_url: "https://login.microsoftonline.com/common/oauth2/v2.0/token",
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
      scope: "openid email profile User.Read"
    })
  end

  @impl true
  def client_id, do: Config.microsoft_client_id!()

  @impl true
  def client_secret, do: Config.microsoft_client_secret!()

  @impl true
  def fetch_identity(code) do
    with {:ok, token} <- request_token(code),
         {:ok, profile} <- Shared.fetch_profile(token, @oauth_user_url, headers: @oauth_headers) do
      {:ok, to_string(profile["id"])}
    end
  end
end
