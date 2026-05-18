defmodule EzAuth.Strategies.SmsOtp do
  @moduledoc false

  use EzAuth.Strategy,
    id: :sms_otp,
    name: "phone",
    identity: :phone,
    kind: :passwordless,
    callback_methods: [:post]

  alias Ecto.Changeset
  alias EzAuth.Accounts
  alias EzAuth.Accounts.User

  @impl true
  def request(conn, %{"user" => user_params}) do
    changeset = User.sign_in_with_phone_changeset(user_params)

    with {:ok, _user} <- Changeset.apply_action(changeset, :validate),
         {:ok, phone} <- Changeset.fetch_change(changeset, :phone),
         {:ok, {user, identity}} <- Accounts.find_or_create_phone_identity(phone) do
      Accounts.request_phone_verification_code(identity)
      {:ok, conn, user}
    end
  end

  @impl true
  def callback(conn, %{"phone" => phone, "code" => code}) do
    with {:ok, verification} <- Accounts.verify_code(code, :phone, phone) do
      {:ok, EzAuth.Auth.sign_in_user(conn, verification.user), verification.user}
    end
  end
end
