defmodule EzAuth.Accounts.VerificationTest do
  use ExUnit.Case, async: true
  use Mimic

  import EzAuth.TestConfig

  alias EzAuth.Accounts.User
  alias EzAuth.Accounts.Token
  alias EzAuth.Accounts.Verification

  describe "build_verification/4" do
    test "stores the hashed token and returns the encoded token to the caller" do
      stub_config()
      user = %User{id: 10}
      token = Token.build_verification_token(format: :random, size: 32, validity: 15)

      assert {encoded_token,
              %Verification{
                user_id: 10,
                type: :email,
                value: "user@example.com",
                token: stored_token,
                expires_at: expires_at
              }} = Verification.build_verification(user, :email, "user@example.com", token)

      refute stored_token == encoded_token
      assert DateTime.compare(expires_at, DateTime.utc_now(:second)) == :gt
    end

    test "stores the hashed code and returns the encoded code to the caller" do
      stub_config()
      user = %User{id: 10}
      token = Token.build_verification_token(format: :code, size: 6, validity: 15)

      assert {encoded_code,
              %Verification{
                user_id: 10,
                type: :email,
                value: "user@example.com",
                token: stored_token,
                expires_at: expires_at
              }} = Verification.build_verification(user, :email, "user@example.com", token)

      assert {:ok, code} = Base.url_decode64(encoded_code, padding: false)
      assert code =~ ~r/^\d{6}$/
      refute stored_token == encoded_code
      assert DateTime.compare(expires_at, DateTime.utc_now(:second)) == :gt
    end
  end

  describe "fetch_by_token_query/2" do
    test "returns :invalid_token for malformed tokens" do
      assert {:error, :invalid_token} = Verification.fetch_by_token_query("bogus", :email)
    end
  end
end
