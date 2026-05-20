defmodule EzAuth.Strategies.PhoneOtpTest do
  use EzAuth.Test.MoxCase, async: true

  import EzAuth.Test.ConnHelpers
  import EzAuth.TestConfig

  alias EzAuth.Accounts
  alias EzAuth.Auth
  alias EzAuth.Strategies.PhoneOtp

  test "uses a post callback for code submission" do
    assert PhoneOtp.__meta__(:callback_methods) == [:post]
  end

  describe "request/2 and callback/2" do
    test "requests a phone OTP, signing up the user on demand if needed" do
      stub_config()
      conn = build_session_conn()
      user = %{id: 1}
      identity = %EzAuth.Accounts.Identity{provider: "phone", value: "+15551234567", user: user}

      expect(Accounts, :find_or_create_phone_identity, fn "+15551234567" ->
        {:ok, {user, identity}}
      end)

      expect(Accounts, :request_phone_verification_code, fn ^identity -> :ok end)

      assert {:ok, ^conn, %{id: 1}} =
               PhoneOtp.request(conn, %{"user" => %{"phone" => "+15551234567"}})
    end

    test "verifies the code and signs the user in" do
      stub_config()
      conn = build_session_conn()
      user = %{id: 1}

      expect(Accounts, :verify_code, fn "123456", :phone, "+15551234567" ->
        {:ok, %{user: user}}
      end)

      expect(Auth, :sign_in_user, fn ^conn, ^user ->
        Plug.Conn.assign(conn, :signed_in, true)
      end)

      assert {:ok, %{assigns: %{signed_in: true}}, %{id: 1}} =
               PhoneOtp.callback(conn, %{"phone" => "+15551234567", "code" => "123456"})
    end

    test "returns the verification failure reason" do
      stub_config()
      conn = build_session_conn()

      expect(Accounts, :verify_code, fn "123456", :phone, "+15551234567" ->
        {:error, :invalid_token}
      end)

      assert {:error, :invalid_token} =
               PhoneOtp.callback(conn, %{"phone" => "+15551234567", "code" => "123456"})
    end
  end
end
