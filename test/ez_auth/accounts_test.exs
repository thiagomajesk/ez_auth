defmodule EzAuth.AccountsTest do
  use EzAuth.Test.DataCase, async: true

  import EzAuth.TestConfig
  import EzAuth.Test.Factory

  alias EzAuth.Accounts
  alias EzAuth.Accounts.Identity
  alias EzAuth.Accounts.User
  alias EzAuth.Accounts.Verification
  alias EzAuth.Scopes.SenderScope
  alias EzAuth.Test.QueryHelpers
  alias EzAuth.Test.Sender
  alias EzAuth.TestRepo

  describe "create_user_with_password/1" do
    test "creates an email user with an unverified identity" do
      base_config()

      attrs =
        :email_sign_up_attrs
        |> build()
        |> Map.put("email", "new@example.com")

      assert {:ok, {%User{id: user_id}, %Identity{type: :email}}} =
               Accounts.create_user_with_password(attrs)

      assert %{user_id: ^user_id, verified_at: nil} =
               QueryHelpers.fetch_identity!(TestRepo, :email, "new@example.com")
    end
  end

  describe "create_user_with_email/1" do
    test "creates a passwordless user with an unverified email identity" do
      base_config()

      assert {:ok, {%User{id: user_id}, identity}} =
               Accounts.create_user_with_email("fresh@example.com")

      assert %Identity{type: :email, value: "fresh@example.com", user: %User{id: ^user_id}} =
               identity

      assert %{user_id: ^user_id, verified_at: nil} =
               QueryHelpers.fetch_identity!(TestRepo, :email, "fresh@example.com")
    end
  end

  describe "create_user_with_phone/1" do
    test "creates a passwordless user with an unverified phone identity" do
      base_config()

      assert {:ok, {%User{id: user_id}, identity}} =
               Accounts.create_user_with_phone("+15551234567")

      assert %Identity{type: :phone, value: "+15551234567", user: %User{id: ^user_id}} = identity

      assert %{user_id: ^user_id, verified_at: nil} =
               QueryHelpers.fetch_identity!(TestRepo, :phone, "+15551234567")
    end
  end

  describe "find_or_create_email_identity/1" do
    test "returns the existing user and identity when verified" do
      base_config()
      user = insert(:user)

      existing =
        insert(:identity,
          user: user,
          type: :email,
          value: "known@example.com",
          verified_at: DateTime.utc_now(:second)
        )

      assert {:ok, {%User{id: user_id}, %Identity{id: identity_id}}} =
               Accounts.find_or_create_email_identity("known@example.com")

      assert user_id == user.id
      assert identity_id == existing.id
    end

    test "creates a passwordless user when no verified identity exists" do
      base_config()

      assert {:ok, {%User{id: user_id}, %Identity{type: :email, value: "fresh@example.com"}}} =
               Accounts.find_or_create_email_identity("fresh@example.com")

      assert %{user_id: ^user_id, verified_at: nil} =
               QueryHelpers.fetch_identity!(TestRepo, :email, "fresh@example.com")
    end
  end

  describe "find_or_create_phone_identity/1" do
    test "creates a passwordless user when no verified identity exists" do
      base_config()

      assert {:ok, {%User{id: user_id}, %Identity{type: :phone, value: "+15551234567"}}} =
               Accounts.find_or_create_phone_identity("+15551234567")

      assert %{user_id: ^user_id, verified_at: nil} =
               QueryHelpers.fetch_identity!(TestRepo, :phone, "+15551234567")
    end
  end

  describe "generate_user_session_token/1" do
    test "creates a session token that can be used to fetch the user" do
      base_config()

      %{user: %{id: user_id} = user} = insert(:identity, verified_at: DateTime.utc_now(:second))

      token = Accounts.generate_user_session_token(user)

      assert %User{id: ^user_id} = Accounts.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_email/1" do
    test "returns nil for unverified email identities" do
      base_config()
      insert(:identity, value: "pending@example.com", verified_at: nil)

      refute Accounts.get_user_by_email("pending@example.com")
    end

    test "returns the user for verified email identities" do
      base_config()

      %{user: %{id: user_id}} =
        insert(:identity, value: "verified@example.com", verified_at: DateTime.utc_now(:second))

      assert %{id: ^user_id} = Accounts.get_user_by_email("verified@example.com")
    end
  end

  describe "get_user_by_username/1" do
    test "returns the user when the username matches" do
      base_config()
      %{id: user_id} = insert(:user, username: "alice")

      assert %User{id: ^user_id} = Accounts.get_user_by_username("alice")
    end

    test "returns nil when no user has that username" do
      base_config()
      refute Accounts.get_user_by_username("nobody")
    end
  end

  describe "get_user_by_session_token/1" do
    test "returns :error for malformed tokens" do
      base_config()
      assert :error = Accounts.get_user_by_session_token("bogus")
    end

    test "returns nil when no token is provided" do
      base_config()
      refute Accounts.get_user_by_session_token(nil)
    end
  end

  describe "email_taken?/1" do
    test "returns false when only unverified rows exist for the value" do
      base_config()
      insert(:identity, value: "pending@example.com", verified_at: nil)

      refute Accounts.email_taken?("pending@example.com")
    end

    test "returns true for verified email identities" do
      base_config()
      insert(:identity, value: "claimed@example.com", verified_at: DateTime.utc_now(:second))

      assert Accounts.email_taken?("claimed@example.com")
    end
  end

  describe "username_taken?/1" do
    test "returns true when a user has that username" do
      base_config()
      insert(:user, username: "alice")

      assert Accounts.username_taken?("alice")
    end

    test "returns false when no user has that username" do
      base_config()
      refute Accounts.username_taken?("nobody")
    end
  end

  describe "issue_identity_verification/2" do
    test "creates a verification and dispatches the encoded token" do
      base_config(%{sender: Sender})

      %{user: %User{id: user_id}} =
        identity = insert(:identity, value: "alice@example.com", verified_at: nil)

      expect(Sender, :deliver, fn :email, %SenderScope{user: %User{id: ^user_id}} -> :ok end)

      assert :ok = Accounts.issue_identity_verification(identity, :email)

      assert %Verification{user_id: ^user_id, type: :email} =
               QueryHelpers.fetch_verification!(TestRepo, :email, "alice@example.com")
    end

    test "replaces previous pending tokens for the same identity" do
      base_config(%{sender: Sender})
      identity = insert(:identity, value: "replace@example.com", verified_at: nil)

      expect(Sender, :deliver, 2, fn :email, _scope -> :ok end)

      assert :ok = Accounts.issue_identity_verification(identity, :email)

      assert %Verification{token: first_token_hash} =
               QueryHelpers.fetch_verification!(TestRepo, :email, "replace@example.com")

      assert :ok = Accounts.issue_identity_verification(identity, :email)

      assert %Verification{token: second_token_hash} =
               QueryHelpers.fetch_verification!(TestRepo, :email, "replace@example.com")

      refute first_token_hash == second_token_hash
      assert TestRepo.aggregate(Verification, :count) == 1
    end
  end

  describe "revoke_user_session_token/1" do
    test "returns :error for malformed tokens" do
      base_config()
      assert :error = Accounts.revoke_user_session_token("bogus")
    end

    test "returns :noop when no token is provided" do
      base_config()
      assert :noop = Accounts.revoke_user_session_token(nil)
    end

    test "revokes a single user session token" do
      base_config()
      user = insert(:user)
      token = Accounts.generate_user_session_token(user)

      assert {1, [raw_token]} = Accounts.revoke_user_session_token(token)
      assert raw_token == Base.url_decode64!(token, padding: false)
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "revoke_user_sessions/1" do
    test "revokes every session for the user and returns the revoked tokens" do
      base_config()
      user = insert(:user)
      token_1 = Accounts.generate_user_session_token(user)
      token_2 = Accounts.generate_user_session_token(user)

      assert {2, tokens} = Accounts.revoke_user_sessions(user)

      assert Enum.sort(tokens) ==
               Enum.sort([
                 Base.url_decode64!(token_1, padding: false),
                 Base.url_decode64!(token_2, padding: false)
               ])

      refute Accounts.get_user_by_session_token(token_1)
      refute Accounts.get_user_by_session_token(token_2)
    end
  end

  describe "update_user_profile/2" do
    test "updates name, username, and metadata" do
      base_config()
      user = insert(:user)

      assert {:ok, updated} =
               Accounts.update_user_profile(user, %{
                 "name" => "Alice",
                 "username" => "alice",
                 "metadata" => %{"role" => "admin"}
               })

      assert %User{name: "Alice", username: "alice", metadata: %{"role" => "admin"}} = updated
    end

    test "keeps unspecified fields unchanged" do
      base_config()
      user = insert(:user, name: "Original", username: "original")

      assert {:ok, %User{name: "Original", username: "updated"}} =
               Accounts.update_user_profile(user, %{"username" => "updated"})
    end

    test "rejects taken usernames" do
      base_config()
      insert(:user, username: "alice")
      user = insert(:user, username: "bob")

      assert {:error, %Ecto.Changeset{errors: errors}} =
               Accounts.update_user_profile(user, %{"username" => "alice"})

      assert {"has already been taken", _opts} = Keyword.fetch!(errors, :username)
    end
  end

  describe "request_password_recovery/1" do
    test "issues a recovery code and dispatches it via the sender for known emails" do
      base_config(%{sender: Sender})

      %{user: %User{id: user_id}} =
        insert(:identity, value: "alice@example.com", verified_at: DateTime.utc_now(:second))

      expect(Sender, :deliver, fn :recovery, %SenderScope{user: %User{id: ^user_id}} -> :ok end)

      assert :ok = Accounts.request_password_recovery("alice@example.com")

      assert %Verification{user_id: ^user_id, type: :recovery} =
               QueryHelpers.fetch_verification!(TestRepo, :recovery, "alice@example.com")
    end

    test "returns :ok silently for unknown emails without dispatching" do
      base_config(%{sender: Sender})

      reject(Sender, :deliver, 2)

      assert :ok = Accounts.request_password_recovery("nobody@example.com")
      assert TestRepo.aggregate(Verification, :count) == 0
    end

    test "replaces a previous recovery code for the same email" do
      base_config(%{sender: Sender})

      insert(:identity, value: "replace@example.com", verified_at: DateTime.utc_now(:second))

      expect(Sender, :deliver, 2, fn :recovery, _scope -> :ok end)

      assert :ok = Accounts.request_password_recovery("replace@example.com")

      %Verification{token: first_hash} =
        QueryHelpers.fetch_verification!(TestRepo, :recovery, "replace@example.com")

      assert :ok = Accounts.request_password_recovery("replace@example.com")

      %Verification{token: second_hash} =
        QueryHelpers.fetch_verification!(TestRepo, :recovery, "replace@example.com")

      refute first_hash == second_hash
      assert TestRepo.aggregate(Verification, :count) == 1
    end
  end

  describe "verify_magic_link/2" do
    test "marks the identity as verified and consumes the token" do
      base_config()

      %{user: %User{id: user_id} = user} =
        insert(:identity, value: "verify@example.com", verified_at: nil)

      {token, _verification} = insert_verification(user, :email, "verify@example.com")

      assert {:ok, %Verification{user: %User{id: ^user_id}}} =
               Accounts.verify_magic_link(token, :email)

      assert QueryHelpers.fetch_identity!(TestRepo, :email, "verify@example.com").verified_at

      assert_raise Ecto.NoResultsError, fn ->
        QueryHelpers.fetch_verification!(TestRepo, :email, "verify@example.com")
      end
    end

    test "returns :invalid_token for expired tokens" do
      base_config()
      %{user: user} = insert(:identity, value: "expired@example.com", verified_at: nil)

      {token, verification} = insert_verification(user, :email, "expired@example.com")

      verification
      |> Ecto.Changeset.change(expires_at: DateTime.add(DateTime.utc_now(:second), -1, :minute))
      |> TestRepo.update!()

      assert {:error, :invalid_token} = Accounts.verify_magic_link(token, :email)
    end

    test "returns :invalid_token for malformed input" do
      base_config()
      assert {:error, :invalid_token} = Accounts.verify_magic_link("bogus", :email)
    end

    test "rejects tokens whose type does not match the caller's expectation" do
      base_config()
      %{user: user} = insert(:identity, value: "other@example.com", verified_at: nil)

      {token, _verification} = insert_verification(user, :recovery, "other@example.com")

      assert {:error, :invalid_token} = Accounts.verify_magic_link(token, :email)
    end

    test "signs the user in when redeeming a token for an already-verified identity" do
      base_config()
      original_verified_at = DateTime.add(DateTime.utc_now(:second), -1, :day)

      %{user: %User{id: user_id} = user} =
        insert(:identity, value: "repeat@example.com", verified_at: original_verified_at)

      {token, _verification} = insert_verification(user, :email, "repeat@example.com")

      assert {:ok, %Verification{user: %User{id: ^user_id}}} =
               Accounts.verify_magic_link(token, :email)

      identity = QueryHelpers.fetch_identity!(TestRepo, :email, "repeat@example.com")
      assert DateTime.compare(identity.verified_at, original_verified_at) == :eq
    end

    test "lets two unverified claims for the same value coexist and resolves by first verifier" do
      base_config()
      %{user: first_user} = insert(:identity, value: "race@example.com", verified_at: nil)
      %{user: second_user} = insert(:identity, value: "race@example.com", verified_at: nil)

      {first_token, _first_verification} =
        insert_verification(first_user, :email, "race@example.com")

      {second_token, _second_verification} =
        insert_verification(second_user, :email, "race@example.com")

      assert {:ok, %Verification{}} = Accounts.verify_magic_link(first_token, :email)

      assert {:error, :already_claimed} =
               Accounts.verify_magic_link(second_token, :email)

      second_row =
        TestRepo.get_by!(Identity,
          user_id: second_user.id,
          type: :email,
          value: "race@example.com"
        )

      refute second_row.verified_at
    end
  end

  describe "verify_magic_code/3" do
    test "consumes the code when value matches and returns the user" do
      base_config()

      %{user: %User{id: user_id} = user} =
        insert(:identity, value: "recover@example.com", verified_at: DateTime.utc_now(:second))

      {code, _verification} = insert_verification(user, :recovery, "recover@example.com")

      assert {:ok, %Verification{type: :recovery, user: %User{id: ^user_id}}} =
               Accounts.verify_magic_code(code, :recovery, "recover@example.com")

      assert_raise Ecto.NoResultsError, fn ->
        QueryHelpers.fetch_verification!(TestRepo, :recovery, "recover@example.com")
      end
    end

    test "returns :invalid_token when value does not match the verification's identity" do
      base_config()

      %{user: user} =
        insert(:identity, value: "recover@example.com", verified_at: DateTime.utc_now(:second))

      {code, _verification} = insert_verification(user, :recovery, "recover@example.com")

      assert {:error, :invalid_token} =
               Accounts.verify_magic_code(code, :recovery, "different@example.com")

      assert %Verification{} =
               QueryHelpers.fetch_verification!(TestRepo, :recovery, "recover@example.com")
    end

    test "returns :invalid_token for malformed input" do
      base_config()

      assert {:error, :invalid_token} =
               Accounts.verify_magic_code("bogus", :recovery, "anyone@example.com")
    end
  end

  describe "User.identities association" do
    test "filters out unverified identity rows" do
      user = insert(:user)
      insert(:identity, user: user, value: "pending@example.com", verified_at: nil)

      insert(:identity,
        user: user,
        value: "verified@example.com",
        verified_at: DateTime.utc_now(:second)
      )

      user = TestRepo.preload(user, :identities)

      assert [%Identity{value: "verified@example.com"}] = user.identities
    end
  end

  defp base_config(overrides \\ %{}) do
    stub_config(
      Map.merge(
        %{strategies: [EzAuth.Strategies.Password]},
        Map.new(overrides)
      )
    )
  end
end
