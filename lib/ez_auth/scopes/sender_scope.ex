defmodule EzAuth.Scopes.SenderScope do
  @moduledoc false

  alias EzAuth.Config
  alias __MODULE__

  defstruct [:user, :token]

  def new(user, token) do
    %SenderScope{user: user, token: token}
  end

  def password_confirmation(%SenderScope{token: token}) do
    Config.endpoint!().url() <> "/auth/password/callback?token=#{token}"
  end
end
