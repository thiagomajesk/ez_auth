defmodule EzAuth.Test.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: EzAuth.TestRepo

  alias EzAuth.Accounts.Identity
  alias EzAuth.Accounts.Session
  alias EzAuth.Accounts.Token
  alias EzAuth.Accounts.User
  alias EzAuth.Accounts.Verification
  alias EzAuth.TestRepo

  def insert_verification_code(user, type, value) do
    token = Token.build_verification_token(format: :code, size: 6, validity: 15)
    {token, verification} = Verification.build_verification(user, type, value, token)
    {token, TestRepo.insert!(verification)}
  end

  def insert_verification_token(user, type, value) do
    token = Token.build_verification_token(format: :random, size: 32, validity: 15)
    {token, verification} = Verification.build_verification(user, type, value, token)
    {token, TestRepo.insert!(verification)}
  end

  def valid_password, do: "valid_password123"

  def email_sign_in_attrs_factory do
    %{
      "email" => sequence(:sign_in_email, &"user#{&1}@example.com"),
      "password" => valid_password()
    }
  end

  def email_sign_up_attrs_factory do
    %{
      "email" => sequence(:sign_up_email, &"user#{&1}@example.com"),
      "password" => valid_password()
    }
  end

  def phone_sign_in_attrs_factory do
    %{"phone" => sequence(:sign_in_phone, &"+1555000#{&1}")}
  end

  def user_factory do
    %User{
      name: "Test User",
      hashed_password: Bcrypt.hash_pwd_salt("valid_password123"),
      anonymous: false
    }
  end

  def identity_factory do
    %Identity{
      user: build(:user),
      type: :email,
      value: sequence(:email, &"user#{&1}@example.com"),
      verified_at: nil
    }
  end

  def session_factory do
    %Session{
      user: build(:user),
      token: :crypto.strong_rand_bytes(32),
      expires_at: DateTime.add(DateTime.utc_now(:second), 60, :day)
    }
  end
end
