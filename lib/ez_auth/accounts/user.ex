defmodule EzAuth.Accounts.User do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias __MODULE__
  alias EzAuth.Accounts
  alias EzAuth.Accounts.Identity
  alias EzAuth.Accounts.Session
  alias EzAuth.Accounts.Verification
  alias EzAuth.Config

  @schema_prefix "auth"
  schema "users" do
    field(:name, :string)
    field(:username, :string)
    field(:metadata, :map, default: %{})
    field(:anonymous, :boolean, default: false)
    field(:hashed_password, :string, redact: true)

    field(:email, :string, virtual: true)
    field(:phone, :string, virtual: true)
    field(:password, :string, virtual: true, redact: true)
    field(:password_confirmation, :string, virtual: true, redact: true)

    has_many(:sessions, Session)
    has_many(:verifications, Verification)
    has_many(:identities, Identity, where: [verified_at: {:not, nil}])

    timestamps(type: :utc_datetime)
  end

  def by_identity_query(type, value) do
    from(u in User,
      join: i in assoc(u, :identities),
      where: i.type == ^type,
      where: i.value == ^value,
      where: not is_nil(i.verified_at)
    )
  end

  def by_username_query(username) do
    from(u in User, where: u.username == ^username)
  end

  def password_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password_format()
    |> maybe_hash_password()
  end

  def profile_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :username, :metadata])
    |> validate_profile_name()
    |> validate_profile_username()
  end

  def sign_in_with_password_changeset(attrs) do
    %User{}
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_email_format()
  end

  def sign_in_with_email_changeset(attrs) do
    %User{}
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_email_format()
  end

  def sign_in_with_phone_changeset(attrs) do
    %User{}
    |> cast(attrs, [:phone])
    |> validate_required([:phone])
    |> validate_phone_format()
  end

  def sign_up_changeset(attrs, opts \\ []) do
    %User{}
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_email_format()
    |> validate_password_format()
    |> maybe_validate_email_available()
    |> maybe_hash_password(opts)
  end

  defp validate_profile_name(changeset) do
    case get_change(changeset, :name) do
      nil -> changeset
      _name -> validate_name_format(changeset)
    end
  end

  defp validate_profile_username(changeset) do
    case get_change(changeset, :username) do
      nil ->
        changeset

      _username ->
        changeset
        |> validate_username_format()
        |> validate_username_available()
    end
  end

  defp validate_username_available(changeset) do
    value = get_change(changeset, :username)

    cond do
      not changeset.valid? -> changeset
      Accounts.username_taken?(value) -> add_error(changeset, :username, "has already been taken")
      true -> changeset
    end
  end

  defp validate_email_format(changeset) do
    {regex, message} = Config.email_format()
    max_length = Config.email_max_length()

    changeset
    |> validate_format(:email, regex, message: message)
    |> validate_length(:email, max: max_length)
  end

  defp validate_name_format(changeset) do
    {regex, message} = Config.name_format()
    max_length = Config.name_max_length()

    changeset
    |> validate_format(:name, regex, message: message)
    |> validate_length(:name, max: max_length)
  end

  defp validate_password_format(changeset) do
    min_length = Config.password_min_length()
    max_length = Config.password_max_length()

    changeset
    |> validate_length(:password,
      min: min_length,
      count: :bytes,
      message: "must be at least %{count} characters"
    )
    |> validate_length(:password,
      max: max_length,
      count: :bytes,
      message: "must be at most %{count} characters"
    )
  end

  defp validate_phone_format(changeset) do
    {regex, message} = Config.phone_format()

    validate_format(changeset, :phone, regex, message: message)
  end

  defp validate_username_format(changeset) do
    {regex, message} = Config.username_format()
    min_length = Config.username_min_length()
    max_length = Config.username_max_length()

    changeset
    |> validate_format(:username, regex, message: message)
    |> validate_length(:username, min: min_length, max: max_length)
  end

  defp maybe_validate_email_available(changeset) do
    value = get_field(changeset, :email)

    cond do
      value in [nil, ""] ->
        changeset

      not changeset.valid? ->
        changeset

      Accounts.email_taken?(value) ->
        add_error(changeset, :email, "has already been taken")

      true ->
        changeset
    end
  end

  defp maybe_hash_password(changeset, opts \\ []) do
    hash_password? = Keyword.get(opts, :hash_password, true)

    case get_change(changeset, :password) do
      nil ->
        changeset

      password when hash_password? ->
        changeset
        |> delete_change(:password)
        |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))

      _password ->
        changeset
    end
  end
end
