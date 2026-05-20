defmodule EzAuth.ConfigTest do
  use ExUnit.Case, async: false

  import EzAuth.Test.Env

  alias EzAuth.Config

  describe "env-backed helpers" do
    test "carry through env values when set" do
      with_env(password_min_length: 12)

      assert Config.password_min_length() == 12
    end

    test "fall back to defaults when unset" do
      with_env([:password_min_length])

      assert Config.password_min_length() == 8
    end

    test "sign_up_path defaults to the generated sign-up page path" do
      with_env([:sign_up_path])

      assert Config.sign_up_path() == "/sign-up"
    end

    test "sign_up_path carries through env values when set" do
      with_env(:sign_up_path, "/join")

      assert Config.sign_up_path() == "/join"
    end

    test "required helpers raise when their key is missing" do
      for {fun, key} <- [
            {&Config.apple_client_id!/0, :apple_client_id},
            {&Config.apple_key_id!/0, :apple_key_id},
            {&Config.apple_private_key!/0, :apple_private_key},
            {&Config.apple_team_id!/0, :apple_team_id},
            {&Config.github_client_id!/0, :github_client_id},
            {&Config.github_client_secret!/0, :github_client_secret},
            {&Config.google_client_id!/0, :google_client_id},
            {&Config.google_client_secret!/0, :google_client_secret},
            {&Config.microsoft_client_id!/0, :microsoft_client_id},
            {&Config.microsoft_client_secret!/0, :microsoft_client_secret},
            {&Config.repo!/0, :repo},
            {&Config.endpoint!/0, :endpoint}
          ] do
        with_env(key, nil)

        assert_raise ArgumentError, "ez_auth config #{inspect(key)} is required", fn ->
          fun.()
        end
      end
    end
  end

  describe "type validation" do
    test "raises when a configured value does not match the declared type" do
      with_env(:password_min_length, "eight")

      assert_raise ArgumentError, ~r/expected :integer/, fn ->
        Config.password_min_length()
      end
    end
  end
end
