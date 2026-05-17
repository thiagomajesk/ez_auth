defmodule EzAuth.FeatureFlagsTest do
  use EzAuth.Test.DataCase, async: true

  import EzAuth.Test.Factory
  import EzAuth.TestConfig

  alias EzAuth.FeatureFlags
  alias EzAuth.FeatureFlags.FeatureFlag
  alias EzAuth.Scopes.UserScope

  describe "put_flag/1 and list_flags/0" do
    test "creates and updates feature flags" do
      stub_config()

      assert {:ok, %FeatureFlag{key: "new-checkout", enabled: false}} =
               FeatureFlags.put_flag(%{
                 "key" => "new-checkout",
                 "description" => "New checkout",
                 "enabled" => false
               })

      assert {:ok, %FeatureFlag{key: "new-checkout", enabled: true}} =
               FeatureFlags.put_flag(%{
                 "key" => "new-checkout",
                 "description" => "New checkout",
                 "enabled" => true
               })

      assert [%FeatureFlag{key: "new-checkout", enabled: true}] = FeatureFlags.list_flags()
    end
  end

  describe "set_enabled/2" do
    test "toggles a feature flag" do
      stub_config()
      insert(:feature_flag, key: "new-checkout", enabled: false)

      assert {:ok, %FeatureFlag{enabled: true}} = FeatureFlags.set_enabled("new-checkout", true)
    end
  end

  describe "enabled?/2" do
    test "returns false for unknown flags and nil scopes" do
      stub_config()

      refute FeatureFlags.enabled?(nil, "missing")
    end

    test "returns true when the flag is globally enabled" do
      stub_config()
      insert(:feature_flag, key: "new-checkout", enabled: true)

      assert FeatureFlags.enabled?(nil, "new-checkout")
    end

    test "requires the configured claim when present" do
      stub_config()
      insert(:feature_flag, key: "billing", enabled: true, claim: "billing:write")

      refute FeatureFlags.enabled?(UserScope.new(%{id: 1}, []), "billing")
      assert FeatureFlags.enabled?(UserScope.new(%{id: 1}, ["billing:write"]), "billing")
    end

    test "returns false when the flag is disabled even if the claim is present" do
      stub_config()
      insert(:feature_flag, key: "billing", enabled: false, claim: "billing:write")

      refute FeatureFlags.enabled?(UserScope.new(%{id: 1}, ["billing:write"]), "billing")
    end
  end
end
