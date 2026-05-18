defmodule EzAuth.Strategies.EmailOtpTest do
  use EzAuth.Test.MoxCase, async: true

  import EzAuth.Test.ConnHelpers
  import EzAuth.TestConfig

  alias EzAuth.Accounts
  alias EzAuth.Auth
  alias EzAuth.Strategies.EmailOtp

  test "uses a post callback for code submission" do
    assert EmailOtp.__meta__(:callback_methods) == [:post]
  end

  describe "request/2 and callback/2" do
    test "requests an email OTP, signing up the user on demand if needed" do
      stub_config()
      conn = build_session_conn()
      user = %{id: 1}
      identity = %EzAuth.Accounts.Identity{type: :email, value: "user@example.com", user: user}

      expect(Accounts, :find_or_create_email_identity, fn "user@example.com" ->
        {:ok, {user, identity}}
      end)

      expect(Accounts, :request_email_verification_code, fn ^identity -> :ok end)

      assert {:ok, ^conn, %{id: 1}} =
               EmailOtp.request(conn, %{"user" => %{"email" => "user@example.com"}})
    end

    test "verifies the code and signs the user in" do
      stub_config()
      conn = build_session_conn()
      user = %{id: 1}

      expect(Accounts, :verify_code, fn "123456", :email, "user@example.com" ->
        {:ok, %{user: user}}
      end)

      expect(Auth, :sign_in_user, fn ^conn, ^user ->
        Plug.Conn.assign(conn, :signed_in, true)
      end)

      assert {:ok, %{assigns: %{signed_in: true}}, %{id: 1}} =
               EmailOtp.callback(conn, %{"email" => "user@example.com", "code" => "123456"})
    end

    test "returns the verification failure reason" do
      stub_config()
      conn = build_session_conn()

      expect(Accounts, :verify_code, fn "123456", :email, "user@example.com" ->
        {:error, :invalid_token}
      end)

      assert {:error, :invalid_token} =
               EmailOtp.callback(conn, %{"email" => "user@example.com", "code" => "123456"})
    end
  end
end
