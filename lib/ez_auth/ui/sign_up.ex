defmodule EzAuth.UI.SignUp do
  @moduledoc """
  Sign-up form as a LiveComponent.

  Renders the email + password form when `EzAuth.Strategies.Password` is
  enabled, plus a stacked list of "Continue with X" buttons for every
  other configured strategy.

  Strategy order is significant. `Config.strategies/0` controls the
  order of rendered sign-in option buttons, including the first buttons
  shown before the user expands the full list.

  When `Password` is not enabled, the form section is omitted and the
  card becomes a launchpad of sign-in option buttons.

  Profile fields (name, username) are not collected here; hosts collect
  them post-login via `EzAuth.Accounts.update_user_profile/2`. Validation
  delegates to `EzAuth.Accounts.User.sign_up_changeset/1`.

  ## Usage

      <.live_component module={EzAuth.UI.SignUp} id="sign-up" />
  """

  use Phoenix.LiveComponent

  import EzAuth.Translations, only: [translate: 1]

  alias Ecto.Changeset
  alias EzAuth.Accounts.User
  alias EzAuth.Config
  alias EzAuth.UI.Core
  alias EzAuth.UI.Core.Buttons
  alias EzAuth.UI.Core.Inputs

  @visible_options 3

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <Core.auth_card
        title={translate("Create your account")}
        subtitle={translate("Welcome! Please fill in the details to get started.")}
      >
        <Core.auth_form
          form={@form}
          :if={show_form?(assigns)}
          action="/auth/sign-up"
          trigger_action={@trigger_action}
          myself={@myself}
        >
          <Inputs.email field={@form[:email]} required />

          <Inputs.password field={@form[:password]} autocomplete="new-password" required />

          <Buttons.submit label={translate("Sign up")} />
        </Core.auth_form>

        <hr :if={show_divider?(assigns)} data-part="divider" />

        <div :if={show_sign_in_options?(assigns)} data-part="sign-in-options">
          <Buttons.strategy
            :for={strategy <- visible_sign_in_options(@strategies)}
            strategy={strategy}
          />

          <button
            :if={has_more_sign_in_options?(@strategies)}
            type="button"
            phx-click="see-more-sign-in-options"
            phx-target={@myself}
            data-part="show-more-sign-in-options"
          >
            {translate("More sign in options")}
          </button>
        </div>

        <div :if={@show_more_options} data-part="sign-in-options">
          <Buttons.strategy :for={strategy <- sign_in_options(@strategies)} strategy={strategy} />

          <button
            type="button"
            phx-click="back"
            phx-target={@myself}
            data-part="back"
          >
            {translate("Back")}
          </button>
        </div>

        <:footer>
          {translate("Already have an account?")}
          <a href={Config.sign_in_path()} data-part="footer-link">
            {translate("Sign in")}
          </a>
        </:footer>
      </Core.auth_card>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:trigger_action, false)
     |> assign(:show_more_options, false)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:strategies, &Config.strategies/0)
     |> assign_new(:form, fn -> to_form(sign_up_changeset(%{})) end)}
  end

  @impl true
  def handle_event("change", %{"user" => user_params}, socket) do
    changeset = sign_up_changeset(user_params)
    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("submit", %{"user" => user_params}, socket) do
    changeset = sign_up_changeset(user_params)

    case Changeset.apply_action(changeset, :validate) do
      {:ok, _user} ->
        {:noreply, assign(socket, :trigger_action, true)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("see-more-sign-in-options", _params, socket),
    do: {:noreply, assign(socket, :show_more_options, true)}

  def handle_event("back", _params, socket),
    do: {:noreply, assign(socket, :show_more_options, false)}

  defp sign_in_options(strategies),
    do: Enum.filter(strategies, &(&1.__meta__(:kind) in [:passwordless, :social]))

  defp has_more_sign_in_options?(strategies),
    do: length(sign_in_options(strategies)) > @visible_options

  defp credential_enabled?(strategies),
    do: Enum.any?(strategies, &(&1.__meta__(:kind) == :credential))

  defp show_divider?(assigns),
    do: show_form?(assigns) and show_sign_in_options?(assigns)

  defp show_form?(assigns),
    do: not assigns.show_more_options and credential_enabled?(assigns.strategies)

  defp show_sign_in_options?(assigns),
    do: not assigns.show_more_options and sign_in_options(assigns.strategies) != []

  defp sign_up_changeset(attrs), do: User.sign_up_changeset(attrs)

  defp visible_sign_in_options(strategies),
    do: Enum.take(sign_in_options(strategies), @visible_options)
end
