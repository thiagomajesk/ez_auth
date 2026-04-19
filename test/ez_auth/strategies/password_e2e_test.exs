defmodule EzAuth.Strategies.PasswordE2ETest do
  use EzAuth.Test.DataCase, async: true

  import EzAuth.Test.ConnHelpers
  import EzAuth.Test.Factory
  import EzAuth.TestConfig
  import Plug.Conn

  alias EzAuth.Strategies.Password

  describe "request/2" do
    test "signs the user in with real persistence and no mocks" do
      stub_config()
      insert(:identity, value: "user@example.com", verified_at: DateTime.utc_now(:second))
      params = Map.put(build(:email_sign_in_attrs), "email", "user@example.com")

      assert {:ok, conn, %{id: _signed_in_user_id}} =
               Password.request(build_session_conn(), params)

      assert get_session(conn, :user_token)
    end

    test "returns invalid credentials for a missing user" do
      stub_config()
      params = Map.put(build(:email_sign_in_attrs), "email", "missing@example.com")

      assert {:error, :invalid_credentials} =
               Password.request(build_session_conn(), params)
    end
  end
end
