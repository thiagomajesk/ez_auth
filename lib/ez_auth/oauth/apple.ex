defmodule EzAuth.OAuth.Apple do
  @moduledoc false

  @keys_url "https://appleid.apple.com/auth/keys"

  def client_secret(client_id, team_id, key_id, private_key) do
    now = System.system_time(:second)

    header = %{"alg" => "ES256", "kid" => key_id, "typ" => "JWT"}

    claims = %{
      "aud" => "https://appleid.apple.com",
      "exp" => now + 15_552_000,
      "iat" => now,
      "iss" => team_id,
      "sub" => client_id
    }

    signing_input = encode_json(header) <> "." <> encode_json(claims)
    signature = :public_key.sign(signing_input, :sha256, decode_private_key(private_key))
    signing_input <> "." <> Base.url_encode64(signature, padding: false)
  end

  def verify_id_token(id_token, client_id) do
    with [header, payload, signature] <- String.split(id_token, "."),
         {:ok, %{"kid" => kid}} <- decode_segment(header),
         {:ok, %{"keys" => keys}} <- fetch_keys(),
         {:ok, public_key} <- public_key(keys, kid),
         :ok <- verify_signature(header <> "." <> payload, signature, public_key),
         {:ok, json} <- Base.url_decode64(payload, padding: false),
         {:ok, claims} <- Jason.decode(json),
         :ok <- validate_claims(claims, client_id) do
      {:ok, claims}
    else
      _error -> {:error, :invalid_id_token}
    end
  end

  defp decode_private_key(private_key) do
    [{_type, _der, _encryption} = entry] = :public_key.pem_decode(private_key)
    :public_key.pem_entry_decode(entry)
  end

  defp decode_segment(segment) do
    with {:ok, json} <- Base.url_decode64(segment, padding: false),
         do: Jason.decode(json)
  end

  defp encode_json(value) do
    value
    |> Jason.encode!()
    |> Base.url_encode64(padding: false)
  end

  defp fetch_keys do
    case Req.get(@keys_url) do
      {:ok, response} when response.status in 200..299 -> {:ok, response.body}
      {:ok, _response} -> {:error, :provider_request_failed}
      error -> error
    end
  end

  defp public_key(keys, kid) do
    case Enum.find(keys, &(&1["kid"] == kid)) do
      %{"kty" => "RSA", "n" => modulus, "e" => exponent} ->
        {:ok, {:RSAPublicKey, decode_uint(modulus), decode_uint(exponent)}}

      _key ->
        {:error, :invalid_id_token}
    end
  end

  defp decode_uint(value) do
    value
    |> Base.url_decode64!(padding: false)
    |> :binary.decode_unsigned()
  end

  defp validate_claims(
         %{"aud" => client_id, "iss" => "https://appleid.apple.com", "exp" => exp},
         client_id
       )
       when is_integer(exp) do
    if exp > System.system_time(:second),
      do: :ok,
      else: {:error, :invalid_id_token}
  end

  defp validate_claims(_claims, _client_id), do: {:error, :invalid_id_token}

  defp verify_signature(signing_input, signature, public_key) do
    signature = Base.url_decode64!(signature, padding: false)

    if :public_key.verify(signing_input, :sha256, signature, public_key),
      do: :ok,
      else: {:error, :invalid_id_token}
  end
end
