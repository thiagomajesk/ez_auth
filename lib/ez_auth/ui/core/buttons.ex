defmodule EzAuth.UI.Core.Buttons do
  @moduledoc """
  Button components used throughout EzAuth flows.

  `submit/1` is the primary call-to-action inside a form. `action/1` is
  the generic button primitive (icon + optional label, plus
  caller-supplied attributes). `strategy/1` renders any strategy as a
  form-submit action button.
  """

  use Phoenix.Component

  import EzAuth.Translations, only: [translate: 1, translate: 2]

  alias EzAuth.Config
  alias EzAuth.Strategy
  alias EzAuth.UI.Core

  @doc """
  Renders a form submit button with a trailing forward arrow.

  ## Options

    * `:label` - button text. Defaults to translated `"Continue"`.

  ## Styling

    * `[data-part="submit"]` - submit button.

  ## Examples

      <EzAuth.UI.Core.Buttons.submit />
      <EzAuth.UI.Core.Buttons.submit label="Sign in" />
  """
  attr(:label, :string, default: nil)
  attr(:rest, :global, include: ~w(disabled))

  def submit(assigns) do
    ~H"""
    <.action
      icon="arrow_right"
      label={submit_label(@label)}
      type={:submit}
      variant="submit"
      {@rest}
    />
    """
  end

  @doc """
  Renders a generic button.

  Always renders a `<button>`. Both `:icon` and `:label` are optional;
  callers attach behaviour and Phoenix LiveView attributes (`phx-click`,
  `phx-target`, etc.) through `:rest`.

  ## Options

    * `:icon` - optional icon name supported by `EzAuth.UI.Core.icon/1`. Always
      rendered to the left of the label at a fixed size.
    * `:label` - optional text rendered next to the icon.
    * `:variant` - the `data-part` written on the rendered `<button>`.
      Defaults to `"action"`. `submit/1` and other wrappers can pass a
      different value to attach their own CSS hook.
    * `:type` - button type. One of `:button` (default) or `:submit`.
      The default avoids accidental parent-form submission; pass `:submit`
      explicitly for form CTAs.

  ## Styling

    * `[data-part="{variant}"]` - the button container.
    * `[data-part="action-label"]` - the label span (only when `:label`
      is set).

  ## Examples

      <EzAuth.UI.Core.Buttons.action icon="google" type={:submit} />
      <EzAuth.UI.Core.Buttons.action icon="github" label="Sign in with GitHub" phx-click="oauth_github" />
  """
  attr(:icon, :string, default: nil)
  attr(:label, :string, default: nil)
  attr(:variant, :string, default: "action")
  attr(:type, :atom, values: [:button, :submit], default: :button)
  attr(:rest, :global, include: ~w(name value title disabled))

  def action(assigns) do
    ~H"""
    <button type={to_string(@type)} data-part={@variant} {@rest}>
      <span data-part="action-content">
        <Core.icon :if={@icon} name={@icon} size={20} />
        <span :if={@label} data-part="action-label">{@label}</span>
      </span>
    </button>
    """
  end

  @doc """
  Renders a strategy as a form-submit action button.

  Derives the icon and label from the strategy's callbacks: identity drives
  the icon (with `"magic_link"` overriding to `"link"`); name fills the
  "Continue with {name}" label. Social strategies submit a POST request.
  Passwordless strategies submit a GET request to the sign-in page with the
  selected strategy.

  ## Options

    * `:strategy` - the strategy module (required).

  ## Styling

    * `[data-part="action"]` - the button container.
    * `[data-strategy={provider}]` - strategy provider on the button.

  ## Examples

      <EzAuth.UI.Core.Buttons.strategy strategy={EzAuth.Strategies.Google} />
  """
  attr(:strategy, :atom, required: true)
  attr(:rest, :global)

  def strategy(assigns) do
    meta = assigns.strategy.__meta__()
    {method, action} = strategy_metadata(assigns.strategy)

    assigns =
      assigns
      |> assign(:provider, meta.provider)
      |> assign(:action, action)
      |> assign(:method, method)
      |> assign(:title, meta.name)
      |> assign(:icon, icon_for(meta))
      |> assign(:slug, Strategy.slug(assigns.strategy))
      |> assign(:label, translate("Continue with %{name}", name: meta.name))

    ~H"""
    <.form for={%{}} action={@action} method={@method}>
      <.action
        icon={@icon}
        label={@label}
        type={:submit}
        name="strategy"
        value={@slug}
        title={@title}
        data-strategy={@provider}
        {@rest}
      />
    </.form>
    """
  end

  defp icon_for(%{provider: "magic_link"}), do: "link"
  defp icon_for(%{provider: "whatsapp"}), do: "whatsapp"
  defp icon_for(%{kind: :social} = meta), do: meta.provider
  defp icon_for(%{identity: :email}), do: "envelope"
  defp icon_for(%{identity: :phone}), do: "phone"

  defp strategy_metadata(strategy) do
    case strategy.__meta__(:kind) do
      :credential ->
        {"get", Config.sign_in_path()}

      :passwordless ->
        {"get", Config.sign_in_path()}

      :social ->
        {"post", "/auth/#{Strategy.slug(strategy)}/request"}
    end
  end

  defp submit_label(nil), do: translate("Continue")
  defp submit_label(label), do: translate(label)
end
