defmodule EzAuth.Accounts.Token do
  @moduledoc false

  alias __MODULE__
  alias EzAuth.Config

  defstruct [:raw_token, :encoded_token, :expires_at]

  def build_session do
    raw = :crypto.strong_rand_bytes(Config.token_rand_size())
    build(raw, Config.session_validity_in_minutes())
  end

  def build_verification_code do
    code = generate_code(Config.recovery_code_length())
    build(code, Config.recovery_code_validity_in_minutes())
  end

  def build_verification_link do
    raw = :crypto.strong_rand_bytes(Config.token_rand_size())
    build(raw, Config.magic_link_validity_in_minutes())
  end

  defp build(value, validity_in_minutes) do
    %Token{
      raw_token: value,
      encoded_token: Base.url_encode64(value, padding: false),
      expires_at: DateTime.add(DateTime.utc_now(:second), validity_in_minutes, :minute)
    }
  end

  defp generate_code(digits) do
    fun = fn -> Enum.random(0..9) end

    fun
    |> Stream.repeatedly()
    |> Enum.take(digits)
    |> Enum.join()
  end
end
