defmodule EzAuth.UI.SignIn do
  @moduledoc """
  Sign-in form as a LiveComponent.

  Renders a single polymorphic identity input that detects email or
  phone shape as the user types. When the typed value is an email
  and a credential strategy is enabled, the password input reveals
  itself. When any passwordless strategy is also enabled, a
  "Continue without a password" button appears below the submit
  button so the user can skip credential entry.

  Social-login buttons render below the form, in `Config.strategies/0`
  order. Verification (post-link, post-code) is the responsibility of
  `EzAuth.UI.TaskVerifyAccount`.

  Validation delegates to `EzAuth.Accounts.User`.

  ## Usage

      <.live_component module={EzAuth.UI.SignIn} id="sign-in" />
  """

  use Phoenix.LiveComponent

  import EzAuth.Translations, only: [translate: 1]

  alias EzAuth.Accounts.User
  alias EzAuth.Config
  alias EzAuth.Strategy
  alias EzAuth.UI.Core
  alias EzAuth.UI.Core.Buttons
  alias EzAuth.UI.Core.Inputs
  alias EzAuth.UI.TaskForgotPassword

  @impl true
  def render(%{recovery: true} = assigns) do
    ~H"""
    <div id={@id}>
      <.live_component
        module={TaskForgotPassword}
        id={"#{@id}-forgot-password"}
        email={@identity}
      />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <Core.auth_card
        title={translate("Sign in to your account")}
        subtitle={translate("Welcome back! Please sign in to continue.")}
      >
        <Core.auth_form
          form={@form}
          action={request_path(@strategies, @detected)}
          trigger_action={@trigger_action}
          myself={@myself}
        >
          <Inputs.poly
            id={"#{@id}-identity"}
            accepts={inputable_identities(@strategies)}
            identity={@detected}
            field={@detected && @form[@detected]}
            value={@identity}
          />

          <Inputs.password
            :if={show_password?(assigns)}
            field={@form[:password]}
            autocomplete="current-password"
            required
          />

          <a
            :if={show_password?(assigns)}
            href="#"
            phx-target={@myself}
            phx-click="forgot-password"
            data-part="forgot-password"
          >
            {translate("Forgot password?")}
          </a>

          <Buttons.submit label={translate("Sign in")} disabled={disable_submit?(assigns)} />

          <button
            :if={show_skip_password_option?(assigns)}
            type="submit"
            formaction={skip_password_path(assigns)}
            formnovalidate
            data-part="hint"
          >
            <small>{translate("Continue without a password")}</small>
          </button>
        </Core.auth_form>

        <hr data-part="divider" />

        <div data-part="social-providers" data-stacked>
          <Buttons.strategy :for={strategy <- social_strategies(@strategies)} strategy={strategy} />
        </div>

        <:footer>
          {translate("Don't have an account?")}
          <a href="/auth/sign-up" data-part="footer-link">
            {translate("Sign up")}
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
     |> assign(:identity, nil)
     |> assign(:detected, nil)
     |> assign(:trigger_action, false)
     |> assign(:recovery, false)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:strategies, &Config.strategies/0)
     |> assign_new(:form, fn -> to_form(%{}, as: nil) end)}
  end

  @impl true
  def handle_event("change", %{"identity" => identity} = params, socket) do
    %{strategies: strategies} = socket.assigns
    available_identities = inputable_identities(strategies)
    detected = detect_identity(identity, available_identities)

    changeset =
      params
      |> normalize_params(detected)
      |> sign_in_changeset(detected, strategies)

    {:noreply,
     socket
     |> assign(:identity, identity)
     |> assign(:detected, detected)
     |> assign(:form, to_form(changeset, as: nil))}
  end

  def handle_event("forgot-password", _params, socket),
    do: {:noreply, assign(socket, :recovery, true)}

  def handle_event("cancel-recovery", _params, socket),
    do: {:noreply, assign(socket, :recovery, false)}

  def handle_event("submit", %{"identity" => identity} = params, socket) do
    %{strategies: strategies, detected: detected} = socket.assigns

    changeset =
      params
      |> normalize_params(detected)
      |> sign_in_changeset(detected, strategies)

    case Ecto.Changeset.apply_action(changeset, :validate) do
      {:ok, _} ->
        {:noreply, assign(socket, :trigger_action, true)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:identity, identity)
         |> assign(:form, to_form(changeset, as: nil, action: :validate))}
    end
  end

  defp inputable_identities(strategies) do
    strategies
    |> Enum.reject(&(&1.__meta__(:kind) == :social))
    |> Enum.map(& &1.__meta__(:identity))
    |> Enum.uniq()
  end

  defp social_strategies(strategies) do
    strategies
    |> Enum.filter(&(&1.__meta__(:kind) == :social))
    |> Enum.uniq_by(& &1.__meta__(:identity))
  end

  # Reveal password when a credential strategy is enabled
  # and the user typed an email (or hasn't typed yet).
  defp show_password?(assigns) do
    assigns.detected in [:email, nil] and
      Enum.any?(assigns.strategies, &(&1.__meta__(:kind) == :credential))
  end

  defp show_skip_password_option?(assigns),
    do: show_password?(assigns) and passwordless_enabled?(assigns.strategies)

  defp passwordless_enabled?(strategies),
    do: Enum.any?(strategies, &(&1.__meta__(:kind) == :passwordless))

  defp skip_password_path(assigns) do
    assigns.strategies
    |> Enum.filter(&(&1.__meta__(:kind) == :passwordless))
    |> request_path(assigns.detected)
  end

  defp request_path(_strategies, nil), do: nil

  defp request_path(strategies, identity) do
    if strategy = Enum.find(strategies, &(&1.__meta__(:identity) == identity)),
      do: "/auth/#{Strategy.slug(strategy)}/request"
  end

  defp disable_submit?(assigns),
    do: request_path(assigns.strategies, assigns.detected) == nil

  defp sign_in_changeset(attrs, nil, _strategies),
    do: Ecto.Changeset.cast(%User{}, attrs, [:password])

  defp sign_in_changeset(attrs, :phone, _strategies),
    do: User.sign_in_with_phone_changeset(attrs)

  defp sign_in_changeset(attrs, :email, strategies) do
    if Enum.any?(strategies, &(&1.__meta__(:kind) == :credential)),
      do: User.sign_in_with_password_changeset(attrs),
      else: User.sign_in_with_email_changeset(attrs)
  end

  defp normalize_params(params, detected) do
    key = detected || "identity"
    user = Map.get(params, "user", %{})
    Map.put(user, to_string(key), params["identity"])
  end

  # This code is purposefully naive — it's about UX feedback, not validation.
  # We only check what looks like an email or phone to guide the user because
  # validating here would punish them before they know what needs to be typed.
  defp detect_identity(value, available) when is_binary(value) do
    detection_patterns = %{email: ~r/@/, phone: ~r/^[+\d]/}

    Enum.find_value(available, fn identity ->
      pattern = detection_patterns[identity]
      if pattern && value =~ pattern, do: identity
    end)
  end
end
