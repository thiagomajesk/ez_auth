defmodule EzAuth.Scopes.SenderScope do
  @moduledoc false

  alias __MODULE__

  defstruct [:user, :token]

  def new(user, token) do
    %SenderScope{user: user, token: token}
  end
end
