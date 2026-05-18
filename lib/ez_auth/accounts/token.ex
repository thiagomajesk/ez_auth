defmodule EzAuth.Accounts.Token do
  @moduledoc false

  alias __MODULE__
  alias EzAuth.Config

  @default_code_size 6
  @default_random_size 32
  @default_validity_in_minutes 15

  defstruct [:raw_token, :encoded_token, :expires_at, :type]

  def build_session do
    raw = :crypto.strong_rand_bytes(Config.token_rand_size())
    build(raw, Config.session_validity_in_minutes())
  end

  def build_verification_token(opts) do
    format = Keyword.get(opts, :format, :random)
    size = Keyword.get(opts, :size, default_size(format))
    validity = Keyword.get(opts, :validity, @default_validity_in_minutes)

    case format do
      :code ->
        build(generate_code(size), validity, :code)

      :random ->
        build(:crypto.strong_rand_bytes(size), validity, :random)
    end
  end

  defp build(value, validity_in_minutes, type \\ nil) do
    %Token{
      type: type,
      raw_token: value,
      encoded_token: Base.url_encode64(value, padding: false),
      expires_at: DateTime.add(DateTime.utc_now(:second), validity_in_minutes, :minute)
    }
  end

  defp default_size(:code), do: @default_code_size
  defp default_size(:random), do: @default_random_size

  defp generate_code(digits) do
    fun = fn -> Enum.random(0..9) end

    fun
    |> Stream.repeatedly()
    |> Enum.take(digits)
    |> Enum.join()
  end
end
