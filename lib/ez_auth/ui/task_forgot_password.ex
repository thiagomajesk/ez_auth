defmodule EzAuth.UI.TaskForgotPassword do
  @moduledoc """
  Password-recovery orchestrator as a LiveComponent.

  Walks the user through three named steps that mirror the strategy lifecycle:

    * default (no `:step`) - email entry; submit triggers the request action
    * `:request` - request action completed; neutral "check your inbox" + "I've received a code" affordance
    * `:verify` - delegates to `TaskVerifyAccount` for code entry
    * `:reset` - delegates to `TaskResetPassword` for the new password

  On successful reset, the user is redirected to `Config.sign_in_path()` so they
  re-authenticate with their new password (no auto-sign-in).

  Pass the typed `email` (if any) so the email-entry form prefills it.

  Children (`TaskVerifyAccount`, `TaskResetPassword`) are rendered without
  an `on_back` so their "Back" button is hidden — once the user is in the
  recovery flow, stepping back doesn't carry useful state to recover.

  ## Usage

      <.live_component
        module={EzAuth.UI.TaskForgotPassword}
        id="forgot-password"
        email={@identity}
      />
  """

  use Phoenix.LiveComponent

  import EzAuth.Translations, only: [translate: 1, translate: 2]

  alias EzAuth.Accounts
  alias EzAuth.Config
  alias EzAuth.UI.Core
  alias EzAuth.UI.Core.Buttons
  alias EzAuth.UI.Core.Inputs
  alias EzAuth.UI.TaskResetPassword
  alias EzAuth.UI.TaskVerifyAccount

  @impl true
  def render(%{step: :verify} = assigns) do
    ~H"""
    <div id={@id}>
      <.live_component
        module={TaskVerifyAccount}
        id={"#{@id}-verify"}
        identity={@email}
        target={@myself}
      />
    </div>
    """
  end

  def render(%{step: :reset} = assigns) do
    ~H"""
    <div id={@id}>
      <.live_component
        module={TaskResetPassword}
        id={"#{@id}-reset"}
        user={@user}
      />
    </div>
    """
  end

  def render(%{step: :request} = assigns) do
    ~H"""
    <div id={@id}>
      <Core.auth_card
        title={translate("Check your inbox")}
        subtitle={
          translate("If we have an account for %{email}, a recovery code is on its way.",
            email: @email
          )
        }
      >
        <Buttons.action
          icon={:arrow_right}
          label={translate("I've received a code")}
          variant="submit"
          phx-target={@myself}
          phx-click="received-code"
        />

        <:footer>
          {translate("Remember your password?")}
          <a href={Config.sign_in_path()} data-part="footer-link">
            {translate("Sign in")}
          </a>
        </:footer>
      </Core.auth_card>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <Core.auth_card
        title={translate("Forgot your password?")}
        subtitle={translate("Enter your email and we'll send you a recovery code.")}
      >
        <.form for={%{}} phx-target={@myself} phx-submit="request">
          <Inputs.input
            id={"#{@id}-email"}
            name="email"
            type="email"
            label={translate("Email")}
            value={@email}
            autocomplete="email"
            required
          />

          <Buttons.submit label={translate("Send recovery code")} />
        </.form>

        <:footer>
          {translate("Remember your password?")}
          <a href={Config.sign_in_path()} data-part="footer-link">
            {translate("Sign in")}
          </a>
        </:footer>
      </Core.auth_card>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("request", %{"email" => email}, socket) do
    Accounts.request_password_recovery(email)

    {:noreply,
     socket
     |> assign(:email, email)
     |> assign(:step, :request)}
  end

  def handle_event("received-code", _params, socket) do
    {:noreply, assign(socket, :step, :verify)}
  end

  def handle_event("submit", %{"code" => parts}, socket) do
    code = Enum.join(Map.values(parts))

    case Accounts.verify_magic_code(code, :recovery, socket.assigns.email) do
      {:ok, verification} ->
        {:noreply,
         socket
         |> assign(:user, verification.user)
         |> assign(:step, :reset)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("resend", _params, socket) do
    Accounts.request_password_recovery(socket.assigns.email)
    {:noreply, socket}
  end
end
