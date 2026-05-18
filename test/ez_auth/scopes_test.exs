defmodule EzAuth.ScopesTest do
  use ExUnit.Case, async: true
  use Mimic

  alias EzAuth.Scopes.UserScope

  describe "EzAuth.Scopes.UserScope.new/1" do
    test "returns nil when no user is given" do
      refute UserScope.new(nil)
    end

    test "wraps the user" do
      user = %{id: 1}

      assert %UserScope{user: ^user} = UserScope.new(user)
    end
  end
end
