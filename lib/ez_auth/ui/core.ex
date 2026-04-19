defmodule EzAuth.UI.Core do
  @moduledoc """
  Top-level Core helpers for EzAuth.UI.

  Sub-namespaces (`Core.Buttons`, `Core.Errors`, `Core.Inputs`) group
  focused components by role. This module hosts standalone helpers that
  don't fit a sub-namespace.
  """

  use Phoenix.Component

  alias EzAuth.UI.Core.Icon

  @doc """
  Renders the visual card of an authentication flow: the outer container,
  header (built from `:title` + `:subtitle`), the main `:inner_block`,
  and an optional `:footer`. Used by SignIn, SignUp, and the task flows
  so they share one chrome.

  Phoenix LiveComponents require a static HTML tag at the root of their
  own template, so hosts wrap this in a thin id-only `<div id={@id}>` for
  diff tracking — the visible card lives in this component's `<div>`.

  ## Options

    * `:title` - heading text shown in the header (required).
    * `:subtitle` - supporting text under the title (required).

  ## Slots

    * `:inner_block` - main flow content (required).
    * `:footer` - rendered inside `<footer data-part="footer">` (required).

  ## Styling

    * `[data-part="auth-card"]` - the outer card container.
    * `[data-part="header"]` - the header block.
    * `[data-part="title"]` - the title.
    * `[data-part="subtitle"]` - the subtitle.
    * `[data-part="footer"]` - the footer block.

  ## Examples

      <div id={@id}>
        <EzAuth.UI.Core.auth_card title="Sign in" subtitle="Welcome back!">
          <.form ...>...</.form>

          <:footer>
            Don't have an account?
            <a href="/sign-up" data-part="footer-link">Sign up</a>
          </:footer>
        </EzAuth.UI.Core.auth_card>
      </div>
  """
  attr(:title, :string, required: true)
  attr(:subtitle, :string, required: true)

  slot(:inner_block, required: true)
  slot(:footer, required: true)

  def auth_card(assigns) do
    ~H"""
    <div data-part="auth-card">
      <header data-part="header">
        <h2 data-part="title">{@title}</h2>
        <p data-part="subtitle">{@subtitle}</p>
      </header>

      {render_slot(@inner_block)}

      <footer data-part="footer">
        {render_slot(@footer)}
      </footer>
    </div>
    """
  end

  @doc """
  Renders the shared `<.form>` wrapper used by SignIn and SignUp.

  Encapsulates the boilerplate that's identical across both flows:
  `method="post"`, `phx-target`, `phx-change="change"`, `phx-submit="submit"`,
  and `phx-trigger-action`. The host LiveComponent must implement
  `handle_event/3` clauses for `"change"` and `"submit"`.

  ## Options

    * `:form` - the `Phoenix.HTML.Form` to bind (required).
    * `:action` - the form's `action` URL (required).
    * `:trigger_action` - whether to trigger native form submission (required).
    * `:myself` - the host LiveComponent's `@myself` (required).

  ## Slots

    * `:inner_block` - the form body (required).

  ## Examples

      <EzAuth.UI.Core.auth_form
        form={@form}
        action={Config.sign_up_path()}
        trigger_action={@trigger_action}
        myself={@myself}
      >
        <Inputs.email field={@form[:email]} required />
        <Inputs.password field={@form[:password]} required />
        <Buttons.submit label="Sign up" />
      </EzAuth.UI.Core.auth_form>
  """
  attr(:form, :any, required: true)
  attr(:action, :string, required: true)
  attr(:trigger_action, :boolean, required: true)
  attr(:myself, :any, required: true)

  slot(:inner_block, required: true)

  def auth_form(assigns) do
    ~H"""
    <.form
      for={@form}
      action={@action}
      method="post"
      phx-target={@myself}
      phx-change="change"
      phx-submit="submit"
      phx-trigger-action={@trigger_action}
    >
      {render_slot(@inner_block)}
    </.form>
    """
  end

  @doc """
  Renders an icon SVG inline at the requested size (pixels, applied to
  both width and height).

  Icons are sourced from [Remix Icon](https://remixicon.com) (Apache 2.0).
  Supported names: brand icons (`:apple`, `:facebook`, `:github`, `:google`,
  `:microsoft`, `:x`) and generic UI icons (`:link`, `:phone`, `:envelope`,
  `:arrow_right`). See `EzAuth.UI.Core.Icon` for the exact Remix Icon
  mappings.

  ## Options

    * `:name` - icon atom to render (required).
    * `:size` - edge length in pixels (required).

  ## Styling

    * `[data-part="icon"]` - icon container.
    * `[data-icon={name}]` - icon identity on the container.

  ## Examples

      <EzAuth.UI.Core.icon name={:google} size={20} />
      <EzAuth.UI.Core.icon name={:link} size={20} />
  """
  attr(:name, :atom, required: true)
  attr(:size, :integer, required: true)
  attr(:rest, :global)

  def icon(assigns) do
    ~H"""
    <span data-part="icon" data-icon={@name} {@rest}>
      {Phoenix.HTML.raw(Icon.svg(@name, @size))}
    </span>
    """
  end
end
