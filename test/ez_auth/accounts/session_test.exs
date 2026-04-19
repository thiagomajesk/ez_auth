defmodule EzAuth.Accounts.SessionTest do
  use ExUnit.Case, async: true
  use Mimic

  import EzAuth.TestConfig

  alias EzAuth.Accounts.Session
  alias EzAuth.Accounts.User

  describe "build_session_token/1" do
    test "returns the encoded token and the persisted session data" do
      stub_config()
      user = %User{id: 10}

      assert {encoded_token, %Session{user_id: 10, token: raw_token, expires_at: expires_at}} =
               Session.build_session_token(user)

      assert {:ok, ^raw_token} = Base.url_decode64(encoded_token, padding: false)
      assert DateTime.compare(expires_at, DateTime.utc_now(:second)) == :gt
    end
  end
end
