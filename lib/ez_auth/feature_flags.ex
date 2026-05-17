defmodule EzAuth.FeatureFlags do
  @moduledoc """
  Stores and evaluates feature flags.
  """

  alias EzAuth.Config
  alias EzAuth.FeatureFlags.FeatureFlag
  alias EzAuth.Scopes.UserScope

  @doc """
  Returns true when the flag is enabled for the current scope.
  """
  def enabled?(scope, key) do
    case get_flag(key) do
      %FeatureFlag{enabled: true, claim: nil} -> true
      %FeatureFlag{enabled: true, claim: claim} -> UserScope.claim?(scope, claim)
      _flag -> false
    end
  end

  @doc """
  Fetches a feature flag by key.
  """
  def get_flag(key) do
    Config.repo!().one(FeatureFlag.by_key_query(to_string(key)))
  end

  @doc """
  Lists all feature flags.
  """
  def list_flags do
    Config.repo!().all(FeatureFlag.list_query())
  end

  @doc """
  Creates or updates a feature flag.
  """
  def put_flag(attrs) do
    key = Map.fetch!(attrs, "key")

    flag =
      case get_flag(key) do
        nil -> %FeatureFlag{}
        flag -> flag
      end

    flag
    |> FeatureFlag.changeset(attrs)
    |> Config.repo!().insert_or_update()
  end

  @doc """
  Enables or disables a feature flag.
  """
  def set_enabled(key, enabled) do
    key
    |> get_flag()
    |> FeatureFlag.changeset(%{"enabled" => enabled})
    |> Config.repo!().update()
  end
end
