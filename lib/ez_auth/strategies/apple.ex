defmodule EzAuth.Strategies.Apple do
  @moduledoc false

  use EzAuth.OAuth,
    provider: "apple",
    name: "Apple",
    authorize_url: "https://appleid.apple.com/auth/authorize",
    token_url: "https://appleid.apple.com/auth/token",
    callback_methods: [:post]

  alias EzAuth.Config
  alias EzAuth.OAuth.Apple

  @impl true
  def authorization_query(state) do
    URI.encode_query(%{
      state: state,
      client_id: client_id(),
      redirect_uri: callback_url(),
      response_mode: "form_post",
      response_type: "code",
      scope: "name email"
    })
  end

  @impl true
  def client_id, do: Config.apple_client_id!()

  @impl true
  def client_secret do
    Apple.client_secret(
      Config.apple_client_id!(),
      Config.apple_team_id!(),
      Config.apple_key_id!(),
      Config.apple_private_key!()
    )
  end

  @impl true
  def fetch_identity(code) do
    with {:ok, id_token} <- request_token(code, token_key: "id_token"),
         {:ok, claims} <- Apple.verify_id_token(id_token, Config.apple_client_id!()) do
      {:ok, to_string(claims["sub"])}
    end
  end
end
