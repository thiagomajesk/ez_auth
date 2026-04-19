defmodule EzAuth.UI.TaskResetPasswordTest do
  use EzAuth.Test.DataCase, async: true

  import EzAuth.TestConfig
  import EzAuth.Test.Factory
  import Phoenix.LiveViewTest

  alias EzAuth.Accounts
  alias EzAuth.Accounts.Session
  alias EzAuth.Accounts.User
  alias EzAuth.Test.Endpoint
  alias EzAuth.TestRepo
  alias EzAuth.UI.TaskResetPassword
  alias Phoenix.LiveView.JS

  setup do
    stub_config()
    :ok
  end

  describe "render/1" do
    test "renders new password + confirm password inputs" do
      html = render_component(TaskResetPassword, id: "reset", user: %User{})

      assert html =~ "New password"
      assert html =~ "Confirm password"
      assert html =~ "Reset password"
    end

    test "hides the Back button when on_back is omitted" do
      html = render_component(TaskResetPassword, id: "reset", user: %User{})

      refute html =~ ~s(data-part="back")
    end

    test "shows the Back button when on_back is given" do
      html =
        render_component(TaskResetPassword,
          id: "reset",
          user: %User{},
          on_back: %JS{}
        )

      assert html =~ ~s(data-part="back")
    end
  end

  describe "handle_event/3 'change'" do
    test "surfaces password confirmation mismatch as a field error" do
      socket = build_socket(%User{})

      params = %{"user" => %{"password" => valid_password(), "password_confirmation" => "wrong"}}

      assert {:noreply, %{assigns: %{form: form}}} =
               TaskResetPassword.handle_event("change", params, socket)

      assert {"does not match password", _} =
               Keyword.fetch!(form.errors, :password_confirmation)
    end
  end

  describe "handle_event/3 'submit'" do
    test "updates the password and redirects when validation passes" do
      user = insert(:user, hashed_password: Bcrypt.hash_pwd_salt("oldpass1234"))
      socket = build_socket(user)

      params = %{
        "user" => %{
          "password" => "newpass1234",
          "password_confirmation" => "newpass1234"
        }
      }

      assert {:noreply, after_socket} = TaskResetPassword.handle_event("submit", params, socket)
      assert {:redirect, %{to: "/sign-in"}} = after_socket.redirected

      reloaded = TestRepo.get!(User, user.id)
      assert Bcrypt.verify_pass("newpass1234", reloaded.hashed_password)
    end

    test "returns the changeset with errors when validation fails" do
      socket = build_socket(%User{})

      params = %{
        "user" => %{
          "password" => "short",
          "password_confirmation" => "short"
        }
      }

      assert {:noreply, %{assigns: %{form: form}}} =
               TaskResetPassword.handle_event("submit", params, socket)

      assert form.action == :validate

      assert {"must be at least %{count} characters", _} =
               Keyword.fetch!(form.errors, :password)
    end

    test "revokes all sessions and disconnects live sockets on successful reset" do
      user = insert(:user)
      Accounts.generate_user_session_token(user)
      Accounts.generate_user_session_token(user)
      assert TestRepo.aggregate(Session, :count) == 2

      stub(Endpoint, :broadcast, fn _, _, _ -> :ok end)

      socket = build_socket(user)

      params = %{
        "user" => %{
          "password" => "newpass1234",
          "password_confirmation" => "newpass1234"
        }
      }

      assert {:noreply, _} = TaskResetPassword.handle_event("submit", params, socket)
      assert TestRepo.aggregate(Session, :count) == 0
    end
  end

  defp build_socket(user) do
    %Phoenix.LiveView.Socket{
      endpoint: Endpoint,
      assigns: %{__changed__: %{}, myself: nil, user: user}
    }
  end
end
