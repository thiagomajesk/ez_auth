defmodule EzAuth.Scopes.UserScope do
  @moduledoc false

  alias __MODULE__

  defstruct [:user, claims: []]

  def claim?(nil, _claim), do: false

  def claim?(%UserScope{} = scope, claim) do
    claim in scope.claims
  end

  def new(nil), do: nil

  def new(user, claims \\ []) do
    %UserScope{user: user, claims: claims}
  end
end
