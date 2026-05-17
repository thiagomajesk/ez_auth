defmodule EzAuth.UI.FeatureFlagsDashboard do
  @moduledoc """
  Development dashboard for managing EzAuth feature flags.
  """

  use Phoenix.LiveView

  alias EzAuth.FeatureFlags

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign_flags(socket)}
  end

  @impl true
  def handle_event("save", %{"feature_flag" => attrs}, socket) do
    {:ok, _flag} = FeatureFlags.put_flag(attrs)
    {:noreply, assign_flags(socket)}
  end

  def handle_event("toggle", %{"key" => key, "enabled" => enabled}, socket) do
    {:ok, _flag} = FeatureFlags.set_enabled(key, enabled == "true")
    {:noreply, assign_flags(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main data-part="feature-flags-dashboard">
      <header>
        <h1>Feature flags</h1>
      </header>

      <.form for={%{}} as={:feature_flag} phx-submit="save">
        <input name="feature_flag[key]" placeholder="new-checkout" required />
        <input name="feature_flag[description]" placeholder="Description" />
        <input name="feature_flag[claim]" placeholder="billing:write" />
        <button type="submit">Save flag</button>
      </.form>

      <table>
        <thead>
          <tr>
            <th>Key</th>
            <th>Description</th>
            <th>Claim</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={flag <- @flags}>
            <td>{flag.key}</td>
            <td>{flag.description}</td>
            <td>{flag.claim}</td>
            <td>
              <button
                type="button"
                phx-click="toggle"
                phx-value-key={flag.key}
                phx-value-enabled={to_string(!flag.enabled)}
              >
                {if flag.enabled, do: "Enabled", else: "Disabled"}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </main>
    """
  end

  defp assign_flags(socket) do
    assign(socket, :flags, FeatureFlags.list_flags())
  end
end
