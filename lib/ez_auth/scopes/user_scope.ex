defmodule EzAuth.Scopes.UserScope do
  @moduledoc false

  alias __MODULE__

  defstruct [:user]

  def new(nil), do: nil

  def new(user) do
    %UserScope{user: user}
  end
end
