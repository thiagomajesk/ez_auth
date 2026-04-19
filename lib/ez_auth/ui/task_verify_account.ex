defmodule EzAuth.UI.TaskVerifyAccount do
  @moduledoc """
  Code-entry verification task as a LiveComponent.

  Renders the auth-card chrome (title + subtitle), the identity being
  verified (if given), a `code` input row the user types or pastes the
  code into, a "Resend" link, a submit button, and a "Back" link in the
  footer. Submits the `code[]` params to the parent's `phx-target` so
  the orchestrating LiveView or LiveComponent decides what to do with
  the code.

  Auto-advance, Arrow-key / Backspace navigation, and paste distribution
  across the boxes come from the `CodeInput` hook in
  `priv/static/ez_auth.js`. Hosts must register it on their
  `LiveSocket`.

  Pass `target` (typically `@myself` from the parent) so submit events
  land in the parent's `handle_event/3`. Pass `on_back` as a
  `Phoenix.LiveView.JS` command to enable the "Back" button; omit it
  to hide the button entirely.

  ## Usage

      <.live_component
        module={EzAuth.UI.TaskVerifyAccount}
        id="verify"
        identity="user@example.com"
        target={@myself}
        on_back={JS.navigate("/sign-in")}
      />
  """

  use Phoenix.LiveComponent

  import EzAuth.Translations, only: [translate: 1]

  alias EzAuth.UI.Core
  alias EzAuth.UI.Core.Buttons
  alias EzAuth.UI.Core.Inputs

  @default_length 6

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <Core.auth_card
        title={translate("Verify your account")}
        subtitle={translate("Enter the verification code sent to your account.")}
      >
        <span :if={@identity} data-part="verify-identity">{@identity}</span>

        <.form for={%{}} phx-target={@target} phx-submit="submit">
          <Inputs.code id={"#{@id}-code"} name="code" length={@length} />

          <button
            type="button"
            phx-target={@target}
            phx-click="resend"
            data-part="verify-resend"
          >
            <small>{translate("Didn't receive a code? Resend")}</small>
          </button>

          <Buttons.submit />
        </.form>

        <:footer>
          <button :if={@on_back} type="button" phx-click={@on_back} data-part="back">
            {translate("Back")}
          </button>
        </:footer>
      </Core.auth_card>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:target, fn -> nil end)
     |> assign_new(:on_back, fn -> nil end)
     |> assign_new(:identity, fn -> nil end)
     |> assign_new(:length, fn -> @default_length end)}
  end
end
