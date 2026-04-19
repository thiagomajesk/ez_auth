defmodule EzAuth.UI.TaskResetPassword do
  @moduledoc """
  Password-reset task as a LiveComponent.

  Renders the auth-card chrome (title + subtitle), two password inputs ("New
  password" and "Confirm password"), and a submit button. Owns its own form
  lifecycle: validates password + confirmation match on every keystroke via
  `EzAuth.Accounts.User.password_changeset/2`, then on submit applies the
  changeset and persists the new password directly. Verification of the
  user's identity is the parent's concern; this task only updates.

  On successful reset, every session for the user is revoked and disconnected.
  No opt-out. See `docs/ARCHITECTURE.md` ("Sessions") for the rationale.

  Pass the resolved `user` (already verified upstream). Pass `on_back` as a
  `Phoenix.LiveView.JS` command to enable the "Back" button; omit it to
  hide the button entirely.

  ## Usage

      <.live_component
        module={EzAuth.UI.TaskResetPassword}
        id="reset"
        user={@user}
        on_back={JS.navigate("/sign-in")}
      />
  """

  use Phoenix.LiveComponent

  import EzAuth.Translations, only: [translate: 1]

  alias Ecto.Changeset
  alias EzAuth.Accounts
  alias EzAuth.Accounts.User
  alias EzAuth.Auth
  alias EzAuth.Config
  alias EzAuth.UI.Core
  alias EzAuth.UI.Core.Buttons
  alias EzAuth.UI.Core.Inputs

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <Core.auth_card
        title={translate("Reset your password")}
        subtitle={translate("Choose a new password for your account.")}
      >
        <.form
          for={@form}
          as={:user}
          phx-target={@myself}
          phx-change="change"
          phx-submit="submit"
        >
          <Inputs.input
            field={@form[:password]}
            type="password"
            label={translate("New password")}
            autocomplete="new-password"
            required
          />

          <Inputs.input
            field={@form[:password_confirmation]}
            type="password"
            label={translate("Confirm password")}
            autocomplete="new-password"
            required
          />

          <Buttons.submit label={translate("Reset password")} />
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
    user = Map.fetch!(assigns, :user)
    changeset = User.password_changeset(user, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:on_back, fn -> nil end)
     |> assign_new(:form, fn -> to_form(changeset, as: :user) end)}
  end

  @impl true
  def handle_event("change", %{"user" => params}, socket) do
    changeset = User.password_changeset(socket.assigns.user, params)
    {:noreply, assign(socket, :form, to_form(changeset, as: :user, action: :validate))}
  end

  def handle_event("submit", %{"user" => params}, socket) do
    changeset = User.password_changeset(socket.assigns.user, params)

    case Changeset.apply_action(changeset, :update) do
      {:ok, _user} ->
        user = Config.repo!().update!(changeset)
        {_count, tokens} = Accounts.revoke_user_sessions(user)
        Auth.disconnect_sessions(socket.endpoint, tokens)

        {:noreply, redirect(socket, to: Config.sign_in_path())}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :user, action: :validate))}
    end
  end
end
