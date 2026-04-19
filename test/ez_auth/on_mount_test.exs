defmodule EzAuth.OnMountTest do
  use EzAuth.Test.MoxCase, async: true

  import EzAuth.TestConfig

  alias EzAuth.Accounts
  alias EzAuth.Scopes.UserScope
  alias EzAuth.Test.SocketHelpers

  describe "on_mount/4" do
    test ":assign_current_scope assigns the current scope from the session" do
      stub_config()
      expect(Accounts, :get_user_by_session_token, fn "token" -> %{id: 1} end)

      assert {:cont, %{assigns: %{current_scope: %UserScope{user: %{id: 1}}}}} =
               EzAuth.on_mount(
                 :assign_current_scope,
                 %{},
                 %{"user_token" => "token"},
                 SocketHelpers.build_socket()
               )
    end

    test ":require_authenticated halts and redirects unauthenticated users" do
      stub_config()
      expect(Accounts, :get_user_by_session_token, fn nil -> nil end)

      assert {:halt, socket} =
               EzAuth.on_mount(
                 :require_authenticated,
                 %{},
                 %{},
                 SocketHelpers.build_socket()
               )

      assert socket.assigns.flash["error"] == "You must log in to access this page."
    end
  end
end
