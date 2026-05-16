defmodule EzAuth.ScopesTest do
  use ExUnit.Case, async: true
  use Mimic

  import EzAuth.TestConfig

  alias EzAuth.Scopes.SenderScope
  alias EzAuth.Scopes.UserScope

  describe "EzAuth.Scopes.SenderScope.new/2" do
    test "wraps the user and token" do
      user = %{id: 1}

      assert %SenderScope{user: ^user, token: "token"} = SenderScope.new(user, "token")
    end

    test "builds the password confirmation URL from the configured endpoint" do
      stub_config()

      assert SenderScope.password_confirmation(SenderScope.new(%{id: 1}, "token")) ==
               "http://localhost/auth/password/callback?token=token"
    end
  end

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
