defmodule EzAuth.Scopes.UserScope do
  @moduledoc false

  alias __MODULE__

  defstruct [:user, claims: %{}]

  def new(nil), do: nil

  def new(user, claims \\ []) do
    grouped_claims = Enum.group_by(claims, & &1.scope, & &1.value)
    %UserScope{user: user, claims: grouped_claims}
  end
end
