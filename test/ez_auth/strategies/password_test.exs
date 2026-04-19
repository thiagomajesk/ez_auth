defmodule EzAuth.Strategies.PasswordTest do
  use EzAuth.Test.MoxCase, async: true

  import EzAuth.Test.ConnHelpers
  import EzAuth.Test.Factory
  import EzAuth.TestConfig

  alias EzAuth.Accounts
  alias EzAuth.Auth
  alias EzAuth.Strategies.Password

  describe "request/2" do
    test "signs the user in when the credentials are valid" do
      stub_config()
      params = Map.put(build(:email_sign_in_attrs), "email", "user@example.com")
      conn = build_session_conn()
      user = %{id: 1, hashed_password: Bcrypt.hash_pwd_salt(valid_password())}

      expect(Accounts, :get_user_by_email, fn "user@example.com" -> user end)
      expect(Auth, :sign_in_user, fn ^conn, ^user -> Plug.Conn.assign(conn, :signed_in, true) end)

      assert {:ok, %{assigns: %{signed_in: true}}, %{id: 1}} =
               Password.request(conn, params)
    end

    test "returns changeset errors when the sign in params are invalid" do
      stub_config()
      conn = build_session_conn()

      assert {:error,
              %Ecto.Changeset{
                errors: [password: {"can't be blank", _password_error}]
              }} =
               Password.request(conn, %{"email" => "user@example.com"})
    end

    test "returns invalid credentials when the user is missing" do
      stub_config()
      params = Map.put(build(:email_sign_in_attrs), "email", "missing@example.com")
      conn = build_session_conn()

      expect(Accounts, :get_user_by_email, fn "missing@example.com" -> nil end)

      assert {:error, :invalid_credentials} = Password.request(conn, params)
    end

    test "returns invalid credentials when the password does not match" do
      stub_config()
      params = Map.put(build(:email_sign_in_attrs), "email", "user@example.com")
      conn = build_session_conn()

      expect(Accounts, :get_user_by_email, fn "user@example.com" ->
        %{id: 1, hashed_password: Bcrypt.hash_pwd_salt("another-password")}
      end)

      assert {:error, :invalid_credentials} = Password.request(conn, params)
    end
  end
end
