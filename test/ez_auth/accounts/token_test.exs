defmodule EzAuth.Accounts.TokenTest do
  use ExUnit.Case, async: true
  use Mimic

  import EzAuth.TestConfig

  alias EzAuth.Accounts.Token

  describe "build_session/0" do
    test "returns token data with session expiration" do
      stub_config(token_rand_size: 16, session_validity_in_minutes: 30)

      before = DateTime.utc_now(:second)
      token = Token.build_session()

      assert byte_size(token.raw_token) == 16
      assert {:ok, raw_token} = Base.url_decode64(token.encoded_token, padding: false)
      assert raw_token == token.raw_token
      assert DateTime.compare(token.expires_at, DateTime.add(before, 29, :minute)) == :gt
      assert DateTime.compare(token.expires_at, DateTime.add(before, 31, :minute)) == :lt
    end
  end

  describe "build_verification_token/1" do
    test "returns random token data with the provided expiration" do
      before = DateTime.utc_now(:second)
      token = Token.build_verification_token(format: :random, size: 24, validity: 10)

      assert byte_size(token.raw_token) == 24
      assert {:ok, raw_token} = Base.url_decode64(token.encoded_token, padding: false)
      assert raw_token == token.raw_token
      assert DateTime.compare(token.expires_at, DateTime.add(before, 9, :minute)) == :gt
      assert DateTime.compare(token.expires_at, DateTime.add(before, 11, :minute)) == :lt
    end

    test "returns a numeric code with base64 encoding and the provided expiration" do
      before = DateTime.utc_now(:second)
      token = Token.build_verification_token(format: :code, size: 6, validity: 10)

      assert String.length(token.raw_token) == 6
      assert token.raw_token =~ ~r/^\d{6}$/
      assert {:ok, decoded} = Base.url_decode64(token.encoded_token, padding: false)
      assert decoded == token.raw_token
      assert DateTime.compare(token.expires_at, DateTime.add(before, 9, :minute)) == :gt
      assert DateTime.compare(token.expires_at, DateTime.add(before, 11, :minute)) == :lt
    end

    test "uses internal defaults when no options are provided" do
      before = DateTime.utc_now(:second)
      token = Token.build_verification_token([])

      assert byte_size(token.raw_token) == 32
      assert DateTime.compare(token.expires_at, DateTime.add(before, 14, :minute)) == :gt
      assert DateTime.compare(token.expires_at, DateTime.add(before, 16, :minute)) == :lt
    end
  end
end
