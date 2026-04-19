defmodule EzAuth.UI.TaskForgotPasswordTest do
  use ExUnit.Case, async: true
  use Mimic

  import EzAuth.TestConfig
  import Phoenix.LiveViewTest

  alias EzAuth.Accounts
  alias EzAuth.Accounts.User
  alias EzAuth.Accounts.Verification
  alias EzAuth.UI.TaskForgotPassword

  setup do
    stub_config()
    :ok
  end

  describe "render/1" do
    test "default step renders the email-entry form" do
      html = render_component(TaskForgotPassword, id: "forgot", email: nil)

      assert html =~ "Forgot your password?"
      assert html =~ ~s(autocomplete="email")
      assert html =~ "Send recovery code"
    end

    test "default step prefills the typed email" do
      html =
        render_component(TaskForgotPassword,
          id: "forgot",
          email: "user@example.com"
        )

      assert html =~ ~s(value="user@example.com")
    end

    test ":request step renders the 'check your inbox' confirmation" do
      html =
        render_component(TaskForgotPassword,
          id: "forgot",
          email: "user@example.com",
          step: :request
        )

      assert html =~ "Check your inbox"
      assert html =~ "user@example.com"
      assert html =~ "I&#39;ve received a code"
    end

    test ":verify step delegates to TaskVerifyAccount" do
      html =
        render_component(TaskForgotPassword,
          id: "forgot",
          email: "user@example.com",
          step: :verify
        )

      assert html =~ "Verify your account"
      assert html =~ ~s(autocomplete="one-time-code")
    end

    test ":reset step delegates to TaskResetPassword" do
      html =
        render_component(TaskForgotPassword,
          id: "forgot",
          email: "user@example.com",
          step: :reset,
          user: %User{}
        )

      assert html =~ "Reset your password"
      assert html =~ "New password"
    end
  end

  describe "handle_event/3 'request'" do
    test "calls Accounts.request_password_recovery and transitions to :request" do
      expect(Accounts, :request_password_recovery, fn "user@example.com" -> :ok end)

      socket = build_socket()
      params = %{"email" => "user@example.com"}

      assert {:noreply, %{assigns: %{step: :request, email: "user@example.com"}}} =
               TaskForgotPassword.handle_event("request", params, socket)
    end
  end

  describe "handle_event/3 'received-code'" do
    test "transitions to :verify" do
      socket = build_socket()

      assert {:noreply, %{assigns: %{step: :verify}}} =
               TaskForgotPassword.handle_event("received-code", %{}, socket)
    end
  end

  describe "handle_event/3 'submit' (verify code)" do
    test "verifies the code with the email scope, stores the user, and transitions to :reset" do
      user = %User{id: 42}
      verification = %Verification{type: :recovery, user: user}

      expect(Accounts, :verify_magic_code, fn "123456", :recovery, "user@example.com" ->
        {:ok, verification}
      end)

      socket = build_socket(%{email: "user@example.com"})

      params = %{
        "code" => %{"0" => "1", "1" => "2", "2" => "3", "3" => "4", "4" => "5", "5" => "6"}
      }

      assert {:noreply, %{assigns: %{step: :reset, user: ^user}}} =
               TaskForgotPassword.handle_event("submit", params, socket)
    end

    test "stays on the verify step when the code is invalid" do
      expect(Accounts, :verify_magic_code, fn _code, :recovery, _value ->
        {:error, :invalid_token}
      end)

      socket = build_socket(%{step: :verify, email: "user@example.com"})

      params = %{
        "code" => %{"0" => "9", "1" => "9", "2" => "9", "3" => "9", "4" => "9", "5" => "9"}
      }

      assert {:noreply, %{assigns: %{step: :verify}} = after_socket} =
               TaskForgotPassword.handle_event("submit", params, socket)

      refute Map.has_key?(after_socket.assigns, :user) and after_socket.assigns.user
    end
  end

  describe "handle_event/3 'resend'" do
    test "re-issues the recovery code for the stored email" do
      expect(Accounts, :request_password_recovery, fn "user@example.com" -> :ok end)

      socket = build_socket(%{email: "user@example.com"})

      assert {:noreply, _} = TaskForgotPassword.handle_event("resend", %{}, socket)
    end
  end

  defp build_socket(extra_assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns: Map.merge(%{__changed__: %{}, myself: nil}, extra_assigns)
    }
  end
end
