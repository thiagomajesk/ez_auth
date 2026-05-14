defmodule EzAuth.Config do
  @moduledoc """
  Runtime configuration for EzAuth.

  Each helper reads and validates a single value from the application
  environment. Domain code calls these helpers directly; nothing in the
  library threads a config carrier through public APIs.
  """

  @socials ~w(apple github google microsoft)a

  def after_sign_in_path, do: env(:after_sign_in_path, :string, "/")

  def email_format,
    do:
      env(
        :email_format,
        :format,
        {~r/^[^@\s]+@[^@\s]+$/, "must be a valid email address"}
      )

  def email_max_length, do: env(:email_max_length, :integer, 160)

  def endpoint!, do: env!(:endpoint, :atom)

  def gettext_backend, do: env(:gettext_backend, :atom)

  def magic_link_validity_in_minutes, do: env(:magic_link_validity_in_minutes, :integer, 15)

  def name_format,
    do:
      env(
        :name_format,
        :format,
        {~r/^[\p{L}][\p{L}\p{M}\s'\-.]*$/u,
         "must contain only letters, spaces, hyphens, apostrophes, and periods"}
      )

  def name_max_length, do: env(:name_max_length, :integer, 160)

  def password_max_length, do: env(:password_max_length, :integer, 72)

  def phone_format,
    do:
      env(
        :phone_format,
        :format,
        {~r/^\+[1-9]\d{1,14}$/, "must be in E.164 format"}
      )

  def password_min_length, do: env(:password_min_length, :integer, 8)

  def recovery_code_length, do: env(:recovery_code_length, :integer, 6)

  def recovery_code_validity_in_minutes,
    do: env(:recovery_code_validity_in_minutes, :integer, 15)

  def repo!, do: env!(:repo, :atom)

  def sender!, do: env!(:sender, :atom)

  def session_validity_in_minutes, do: env(:session_validity_in_minutes, :integer, 20_160)

  def sign_in_path, do: env(:sign_in_path, :string, "/sign-in")

  def strategy_enabled?(strategy), do: strategy in strategies()

  def username_format,
    do:
      env(
        :username_format,
        :format,
        {~r/^[A-Za-z][A-Za-z0-9_]*$/,
         "must start with a letter and contain only letters, digits, and underscores"}
      )

  def username_max_length, do: env(:username_max_length, :integer, 64)

  def username_min_length, do: env(:username_min_length, :integer, 3)

  def social_providers do
    EzAuth.Config.strategies()
    |> Enum.map(& &1.__meta__(:id))
    |> Enum.filter(&(&1 in @socials))
  end

  def strategies, do: env(:strategies, :list, [])

  def token_rand_size, do: env(:token_rand_size, :integer, 32)

  defp env(key, type, default \\ nil) do
    case Application.get_env(:ez_auth, key) do
      nil -> default
      value -> check!(key, type, value)
    end
  end

  defp env!(key, type) do
    case env(key, type) do
      nil -> raise ArgumentError, "ez_auth config #{inspect(key)} is required"
      value -> value
    end
  end

  defp check!(_key, :atom, value) when is_atom(value), do: value
  defp check!(_key, :boolean, value) when is_boolean(value), do: value
  defp check!(_key, :integer, value) when is_integer(value), do: value
  defp check!(_key, :list, value) when is_list(value), do: value
  defp check!(_key, :string, value) when is_binary(value), do: value

  defp check!(_key, :format, {%Regex{}, message} = value) when is_binary(message), do: value

  defp check!(key, type, value) do
    raise ArgumentError,
          "ez_auth config #{inspect(key)}: expected #{inspect(type)}, got #{inspect(value)}"
  end
end
