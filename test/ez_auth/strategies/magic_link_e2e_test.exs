defmodule EzAuth.Strategies.MagicLinkE2ETest do
  use EzAuth.Test.DataCase, async: true

  import EzAuth.Test.ConnHelpers
  import EzAuth.Test.Factory
  import EzAuth.TestConfig
  import Plug.Conn

  alias EzAuth.Strategies.MagicLink
  alias EzAuth.Test.QueryHelpers
  alias EzAuth.TestRepo

  describe "request/2 and callback/2" do
    test "creates a verification for a verified email without mocks" do
      stub_config()
      insert(:identity, value: "user@example.com", verified_at: DateTime.utc_now(:second))

      assert {:ok, _conn, %{id: _user_id}} =
               MagicLink.request(build_session_conn(), %{
                 "user" => %{"email" => "user@example.com"}
               })

      assert %{type: :email, value: "user@example.com"} =
               QueryHelpers.fetch_verification!(TestRepo, :email, "user@example.com")
    end

    test "verifies the token and signs the user in without mocks" do
      stub_config()

      %{user: %{id: user_id} = user} =
        insert(:identity, value: "user@example.com", verified_at: nil)

      {token, _verification} = insert_verification_token(user, :email, "user@example.com")

      assert {:ok, conn, %{id: ^user_id}} =
               MagicLink.callback(build_session_conn(), %{"token" => token})

      assert get_session(conn, :user_token)
      assert QueryHelpers.fetch_identity!(TestRepo, :email, "user@example.com").verified_at
    end

    test "returns invalid_token for malformed tokens" do
      stub_config()

      assert {:error, :invalid_token} =
               MagicLink.callback(build_session_conn(), %{"token" => "bogus"})
    end
  end
end
