defmodule EzAuth.Strategies.SmsOtpE2ETest do
  use EzAuth.Test.DataCase, async: true

  import EzAuth.Test.ConnHelpers
  import EzAuth.Test.Factory
  import EzAuth.TestConfig
  import Plug.Conn

  alias EzAuth.Strategies.SmsOtp
  alias EzAuth.Test.QueryHelpers
  alias EzAuth.TestRepo

  describe "request/2 and callback/2" do
    test "creates a phone verification for a verified phone without mocks" do
      stub_config()

      insert(:identity,
        provider: "phone",
        value: "+15551234567",
        verified_at: DateTime.utc_now(:second)
      )

      assert {:ok, _conn, %{id: _user_id}} =
               SmsOtp.request(build_session_conn(), %{
                 "user" => %{"phone" => "+15551234567"}
               })

      assert %{type: :phone, value: "+15551234567"} =
               QueryHelpers.fetch_verification!(TestRepo, :phone, "+15551234567")
    end

    test "verifies the code and signs the user in without mocks" do
      stub_config()

      %{user: %{id: user_id} = user} =
        insert(:identity, provider: "phone", value: "+15551234567", verified_at: nil)

      {code, _verification} = insert_verification_code(user, :phone, "+15551234567")

      assert {:ok, conn, %{id: ^user_id}} =
               SmsOtp.callback(build_session_conn(), %{"phone" => "+15551234567", "code" => code})

      assert get_session(conn, :user_token)
      assert QueryHelpers.fetch_identity!(TestRepo, "phone", "+15551234567").verified_at
    end

    test "returns invalid_token for malformed codes" do
      stub_config()

      assert {:error, :invalid_token} =
               SmsOtp.callback(build_session_conn(), %{
                 "phone" => "+15551234567",
                 "code" => "bogus"
               })
    end
  end
end
