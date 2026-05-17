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
  def callback(conn, %{"user" => user_params}) do
    changeset = User.sign_in_with_phone_code_changeset(user_params)

    with {:ok, _user} <- Changeset.apply_action(changeset, :validate),
         {:ok, phone} <- Changeset.fetch_change(changeset, :phone),
         {:ok, code} <- Changeset.fetch_change(changeset, :code),
         {:ok, verification} <- Accounts.verify_sms_otp(code, phone) do
      {:ok, EzAuth.Auth.sign_in_user(conn, verification.user), verification.user}
    end
  end

  @impl true
  def request(conn, %{"user" => user_params}) do
    changeset = User.sign_in_with_phone_changeset(user_params)

    with {:ok, _user} <- Changeset.apply_action(changeset, :validate),
         {:ok, phone} <- Changeset.fetch_change(changeset, :phone),
         {:ok, {user, identity}} <- Accounts.find_or_create_phone_identity(phone) do
      Accounts.request_sms_otp(identity)
      {:ok, conn, user}
    end
  end
end
