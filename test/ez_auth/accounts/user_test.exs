defmodule EzAuth.Accounts.UserTest do
  use EzAuth.Test.DataCase, async: true

  import EzAuth.TestConfig
  import EzAuth.Test.Factory

  alias EzAuth.Accounts.User

  setup do
    stub_config()
    :ok
  end

  describe "sign_up_changeset/1" do
    test "accepts email + password" do
      attrs =
        :email_sign_up_attrs
        |> build()
        |> Map.put("email", "new@example.com")

      assert {:ok, %User{email: "new@example.com", password: nil, hashed_password: hashed}} =
               validate(attrs)

      assert Bcrypt.verify_pass(attrs["password"], hashed)
    end

    test "rejects invalid email formats" do
      attrs = Map.put(build(:email_sign_up_attrs), "email", "not-an-email")

      assert {:error, %Ecto.Changeset{errors: errors}} = validate(attrs)
      assert {"must be a valid email address", _meta} = Keyword.fetch!(errors, :email)
    end

    test "rejects emails longer than 160 characters" do
      attrs =
        Map.put(
          build(:email_sign_up_attrs),
          "email",
          String.duplicate("a", 161) <> "@example.com"
        )

      assert {:error, %Ecto.Changeset{errors: errors}} = validate(attrs)

      assert {_msg, [count: 160, validation: :length, kind: :max, type: :string]} =
               Keyword.fetch!(errors, :email)
    end

    test "rejects passwords shorter than the minimum" do
      attrs = Map.put(build(:email_sign_up_attrs), "password", "short")

      assert {:error, %Ecto.Changeset{errors: errors}} = validate(attrs)

      assert {"must be at least %{count} characters",
              [count: 8, validation: :length, kind: :min, type: :binary]} =
               Keyword.fetch!(errors, :password)
    end

    test "rejects passwords longer than the configured max" do
      stub_config(password_max_length: 72)
      max = 72
      attrs = Map.put(build(:email_sign_up_attrs), "password", String.duplicate("a", max + 1))

      assert {:error, %Ecto.Changeset{errors: errors}} = validate(attrs)

      assert {"must be at most %{count} characters",
              [count: ^max, validation: :length, kind: :max, type: :binary]} =
               Keyword.fetch!(errors, :password)
    end

    test "rejects when the password is missing" do
      assert {:error, %Ecto.Changeset{errors: errors}} =
               validate(%{"email" => "user@example.com"})

      assert {"can't be blank", _meta} = Keyword.fetch!(errors, :password)
    end

    test "rejects when the email is already taken by a verified identity" do
      insert(:identity, value: "taken@example.com", verified_at: DateTime.utc_now(:second))
      attrs = Map.put(build(:email_sign_up_attrs), "email", "taken@example.com")

      assert {:error, %Ecto.Changeset{errors: errors}} = validate(attrs)
      assert {"has already been taken", _meta} = Keyword.fetch!(errors, :email)
    end
  end

  describe "profile_changeset/2" do
    test "casts name, username, and metadata together" do
      changeset =
        User.profile_changeset(%User{}, %{
          "name" => "Alice",
          "username" => "alice",
          "metadata" => %{"role" => "admin"}
        })

      assert changeset.valid?
      assert changeset.changes.name == "Alice"
      assert changeset.changes.username == "alice"
      assert changeset.changes.metadata == %{"role" => "admin"}
    end

    test "skips name validation when name is absent" do
      changeset = User.profile_changeset(%User{}, %{"username" => "alice"})

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :name)
    end

    test "skips username validation when username is absent" do
      changeset = User.profile_changeset(%User{}, %{"name" => "Alice"})

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :username)
    end

    test "rejects invalid name formats" do
      for name <- ["Alice 1", "Bob123", "user@home", "_underscore"] do
        changeset = User.profile_changeset(%User{}, %{"name" => name})

        refute changeset.valid?

        assert {"must contain only letters, spaces, hyphens, apostrophes, and periods", _opts} =
                 Keyword.fetch!(changeset.errors, :name)
      end
    end

    test "accepts letters, spaces, hyphens, apostrophes, and periods" do
      for name <- ["Alice", "Mary-Anne", "O'Neill", "Dr. Smith", "José"] do
        changeset = User.profile_changeset(%User{}, %{"name" => name})
        assert changeset.valid?
      end
    end

    test "rejects names longer than 160 characters" do
      changeset = User.profile_changeset(%User{}, %{"name" => String.duplicate("A", 161)})

      refute changeset.valid?

      assert {_msg, [count: 160, validation: :length, kind: :max, type: :string]} =
               Keyword.fetch!(changeset.errors, :name)
    end

    test "rejects invalid username formats" do
      changeset = User.profile_changeset(%User{}, %{"username" => "1invalid"})

      refute changeset.valid?

      assert {"must start with a letter and contain only letters, digits, and underscores", _opts} =
               Keyword.fetch!(changeset.errors, :username)
    end

    test "rejects taken usernames" do
      insert(:user, username: "alice")
      changeset = User.profile_changeset(%User{}, %{"username" => "alice"})

      refute changeset.valid?
      assert {"has already been taken", _opts} = Keyword.fetch!(changeset.errors, :username)
    end
  end

  describe "password_changeset/2" do
    test "hashes the password and clears the virtual change on success" do
      changeset =
        User.password_changeset(%User{}, %{
          "password" => valid_password(),
          "password_confirmation" => valid_password()
        })

      assert changeset.valid?
      assert is_binary(changeset.changes.hashed_password)
      refute Map.has_key?(changeset.changes, :password)
      assert Bcrypt.verify_pass(valid_password(), changeset.changes.hashed_password)
    end

    test "requires the password" do
      changeset = User.password_changeset(%User{}, %{})

      refute changeset.valid?
      assert {"can't be blank", _opts} = Keyword.fetch!(changeset.errors, :password)
    end

    test "rejects passwords that do not match the confirmation" do
      changeset =
        User.password_changeset(%User{}, %{
          "password" => valid_password(),
          "password_confirmation" => "different"
        })

      refute changeset.valid?

      assert {"does not match password", _opts} =
               Keyword.fetch!(changeset.errors, :password_confirmation)
    end

    test "rejects passwords shorter than the configured minimum" do
      changeset =
        User.password_changeset(%User{}, %{
          "password" => "short",
          "password_confirmation" => "short"
        })

      refute changeset.valid?

      assert {"must be at least %{count} characters",
              [count: 8, validation: :length, kind: :min, type: :binary]} =
               Keyword.fetch!(changeset.errors, :password)
    end
  end

  describe "sign_in_with_password_changeset/1" do
    test "is valid with email + password" do
      attrs = Map.put(build(:email_sign_in_attrs), "email", "user@example.com")

      assert %Ecto.Changeset{valid?: true, data: %User{}, changes: changes} =
               User.sign_in_with_password_changeset(attrs)

      assert changes.email == "user@example.com"
    end

    test "requires email" do
      changeset = User.sign_in_with_password_changeset(%{"password" => valid_password()})

      refute changeset.valid?
      assert {"can't be blank", _meta} = Keyword.fetch!(changeset.errors, :email)
    end

    test "rejects malformed emails" do
      changeset =
        User.sign_in_with_password_changeset(%{
          "email" => "not-an-email",
          "password" => valid_password()
        })

      refute changeset.valid?
      assert {"must be a valid email address", _meta} = Keyword.fetch!(changeset.errors, :email)
    end

    test "requires password" do
      changeset = User.sign_in_with_password_changeset(%{"email" => "user@example.com"})

      refute changeset.valid?
      assert {"can't be blank", _meta} = Keyword.fetch!(changeset.errors, :password)
    end
  end

  describe "sign_in_with_email_changeset/1" do
    test "is valid with a well-formed email and ignores other fields" do
      changeset =
        User.sign_in_with_email_changeset(%{
          "email" => "user@example.com",
          "password" => valid_password()
        })

      assert %Ecto.Changeset{valid?: true, changes: changes} = changeset
      assert changes.email == "user@example.com"
      refute Map.has_key?(changes, :password)
    end

    test "requires the email" do
      changeset = User.sign_in_with_email_changeset(%{})

      refute changeset.valid?
      assert {"can't be blank", _meta} = Keyword.fetch!(changeset.errors, :email)
    end

    test "rejects malformed emails" do
      changeset = User.sign_in_with_email_changeset(%{"email" => "not-an-email"})

      refute changeset.valid?
      assert {"must be a valid email address", _meta} = Keyword.fetch!(changeset.errors, :email)
    end
  end

  describe "sign_in_with_phone_changeset/1" do
    test "is valid with an E.164 phone" do
      changeset = User.sign_in_with_phone_changeset(%{"phone" => "+15551234567"})

      assert %Ecto.Changeset{valid?: true, changes: changes} = changeset
      assert changes.phone == "+15551234567"
    end

    test "requires the phone" do
      changeset = User.sign_in_with_phone_changeset(%{})

      refute changeset.valid?
      assert {"can't be blank", _meta} = Keyword.fetch!(changeset.errors, :phone)
    end

    test "rejects phones outside E.164 format" do
      for phone <- ["5551234567", "+0123456789", "+1555abc4567", "+1555123456789012"] do
        changeset = User.sign_in_with_phone_changeset(%{"phone" => phone})

        refute changeset.valid?
        assert {"must be in E.164 format", _meta} = Keyword.fetch!(changeset.errors, :phone)
      end
    end
  end

  defp validate(attrs) do
    attrs
    |> User.sign_up_changeset()
    |> Ecto.Changeset.apply_action(:validate)
  end
end
