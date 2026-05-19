defmodule EzAuth.OAuth.AppleTest do
  use ExUnit.Case, async: true

  import EzAuth.TestConfig

  alias EzAuth.OAuth.Apple

  describe "client_secret/4" do
    test "builds an ES256 signed client secret" do
      config = stub_config()

      token =
        Apple.client_secret(
          config.apple_client_id,
          config.apple_team_id,
          config.apple_key_id,
          config.apple_private_key
        )

      assert [header, payload, signature] = String.split(token, ".")
      assert {:ok, %{"alg" => "ES256", "kid" => "apple-key-id"}} = decode_segment(header)

      assert {:ok, %{"aud" => "https://appleid.apple.com", "sub" => "apple-client-id"}} =
               decode_segment(payload)

      assert {:ok, _signature} = Base.url_decode64(signature, padding: false)
    end
  end

  defp decode_segment(segment) do
    with {:ok, json} <- Base.url_decode64(segment, padding: false),
         do: Jason.decode(json)
  end
end
