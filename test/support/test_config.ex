defmodule EzAuth.TestConfig do
  @moduledoc false

  alias EzAuth.Config

  @stubs ~w(
    after_sign_in_path
    email_format
    email_max_length
    endpoint!
    gettext_backend
    magic_link_validity_in_minutes
    name_format
    name_max_length
    password_max_length
    password_min_length
    phone_format
    recovery_code_length
    recovery_code_validity_in_minutes
    repo!
    sender
    session_validity_in_minutes
    sign_in_path
    sign_up_path
    strategies
    token_rand_size
    username_format
    username_max_length
    username_min_length
  )a

  @defaults %{
    repo: EzAuth.TestRepo,
    sender: EzAuth.Test.Sender,
    endpoint: EzAuth.Test.Endpoint,
    gettext_backend: nil,
    strategies: [],
    sign_in_path: "/sign-in",
    sign_up_path: "/sign-up",
    after_sign_in_path: "/",
    password_min_length: 8,
    password_max_length: 72,
    email_format: {~r/^[^@\s]+@[^@\s]+$/, "must be a valid email address"},
    email_max_length: 160,
    phone_format: {~r/^\+[1-9]\d{1,14}$/, "must be in E.164 format"},
    name_format:
      {~r/^[\p{L}][\p{L}\p{M}\s'\-.]*$/u,
       "must contain only letters, spaces, hyphens, apostrophes, and periods"},
    name_max_length: 160,
    username_format:
      {~r/^[A-Za-z][A-Za-z0-9_]*$/,
       "must start with a letter and contain only letters, digits, and underscores"},
    username_min_length: 3,
    username_max_length: 64,
    token_rand_size: 32,
    session_validity_in_minutes: 20_160,
    magic_link_validity_in_minutes: 15,
    recovery_code_length: 6,
    recovery_code_validity_in_minutes: 15
  }

  def stub_config(overrides \\ %{}) do
    values = Map.merge(@defaults, Map.new(overrides))

    for fun <- @stubs do
      key =
        fun
        |> to_string()
        |> String.trim_trailing("!")
        |> String.to_atom()

      Mimic.stub(Config, fun, fn -> Map.fetch!(values, key) end)
    end

    values
  end
end
