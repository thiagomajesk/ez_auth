defmodule EzAuth.Accounts.IdentityTest do
  use ExUnit.Case, async: true

  alias EzAuth.Accounts.Identity
  alias EzAuth.Accounts.User

  describe "changeset/3" do
    test "builds an identity changeset for the user" do
      user = %User{id: 10}

      assert %{valid?: true, changes: %{provider: "email", value: "user@example.com"}} =
               Identity.changeset(user, "email", "user@example.com")
    end
  end
end
