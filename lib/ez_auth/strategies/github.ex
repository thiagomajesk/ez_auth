defmodule EzAuth.Strategies.GitHub do
  @moduledoc false

  use EzAuth.OAuth,
    provider: "github",
    name: "GitHub",
    user_url: "https://api.github.com/user",
    authorize_url: "https://github.com/login/oauth/authorize",
    token_url: "https://github.com/login/oauth/access_token",
    headers: [{"accept", "application/vnd.github+json"}]

  alias EzAuth.Config
  alias EzAuth.OAuth.Shared

  @impl true
  def authorization_query(state) do
    URI.encode_query(%{
      state: state,
      client_id: client_id(),
      redirect_uri: callback_url(),
      scope: "read:user user:email"
    })
  end

  @impl true
  def client_id, do: Config.github_client_id!()

  @impl true
  def client_secret, do: Config.github_client_secret!()

  @impl true
  def fetch_identity(code) do
    with {:ok, token} <- request_token(code),
         {:ok, profile} <- Shared.fetch_profile(token, @oauth_user_url, headers: @oauth_headers) do
      {:ok, to_string(profile["id"])}
    end
  end
end
