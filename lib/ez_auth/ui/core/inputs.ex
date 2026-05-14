defmodule EzAuth.UI.Core.Inputs do
  @moduledoc """
  Form input components for EzAuth flows.

  Each public component wraps a labelled form control. Hosts compose
  these directly: no identity configuration is read here; the caller
  decides which inputs to render.
  """

  use Phoenix.Component

  import EzAuth.Translations, only: [translate: 1]

  alias EzAuth.ErrorHelpers
  alias EzAuth.UI.Core.Errors
  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField

  @doc """
  Renders an email input.

  ## Options

    * `:field` - form field to bind to this input (required).
    * `:required` - whether the field is required. Defaults to `false`.

  ## Styling

    * `[data-part="field"]` - input container.
    * `[data-part="label"]` - visible field label.
    * `[data-part="input"]` - form control.
    * `[data-invalid]` - invalid state on the container.

  ## Examples

      <EzAuth.UI.Core.Inputs.email field={@form[:email]} required />
  """
  attr(:field, FormField, required: true)
  attr(:required, :boolean, default: false)
  attr(:rest, :global)

  def email(assigns) do
    ~H"""
    <.input
      field={@field}
      label={translate("Email")}
      type="email"
      autocomplete="email"
      inputmode="email"
      required={@required}
      {@rest}
    />
    """
  end

  @doc """
  Renders a username input.

  ## Options

    * `:field` - form field to bind to this input (required).
    * `:required` - whether the field is required. Defaults to `false`.

  ## Styling

    * `[data-part="field"]` - input container.
    * `[data-part="label"]` - visible field label.
    * `[data-part="input"]` - form control.
    * `[data-invalid]` - invalid state on the container.

  ## Examples

      <EzAuth.UI.Core.Inputs.username field={@form[:username]} required />
  """
  attr(:field, FormField, required: true)
  attr(:required, :boolean, default: false)
  attr(:rest, :global)

  def username(assigns) do
    ~H"""
    <.input
      field={@field}
      label={translate("Username")}
      autocomplete="username"
      required={@required}
      {@rest}
    />
    """
  end

  @doc """
  Renders a phone input.

  ## Options

    * `:field` - form field to bind to this input (required).
    * `:required` - whether the field is required. Defaults to `false`.

  ## Styling

    * `[data-part="field"]` - input container.
    * `[data-part="label"]` - visible field label.
    * `[data-part="input"]` - form control.
    * `[data-invalid]` - invalid state on the container.

  ## Examples

      <EzAuth.UI.Core.Inputs.phone field={@form[:phone]} required />
  """
  attr(:field, FormField, required: true)
  attr(:required, :boolean, default: false)
  attr(:rest, :global)

  def phone(assigns) do
    ~H"""
    <.input
      field={@field}
      label={translate("Phone")}
      type="tel"
      autocomplete="tel"
      inputmode="tel"
      required={@required}
      {@rest}
    />
    """
  end

  @doc """
  Renders a password input.

  ## Options

    * `:field` - form field to bind to this input (required).
    * `:required` - whether the field is required. Defaults to `false`.
    * `:autocomplete` - browser autocomplete hint. Defaults to
      `"current-password"`. Use `"new-password"` in registration flows.

  ## Styling

    * `[data-part="field"]` - input container.
    * `[data-part="label"]` - visible field label.
    * `[data-part="input"]` - form control.
    * `[data-invalid]` - invalid state on the container.

  ## Examples

      <EzAuth.UI.Core.Inputs.password field={@form[:password]} required />
      <EzAuth.UI.Core.Inputs.password
        field={@form[:password]}
        autocomplete="new-password"
        required
      />
  """
  attr(:field, FormField, required: true)
  attr(:required, :boolean, default: false)
  attr(:autocomplete, :string, default: "current-password")
  attr(:rest, :global)

  def password(assigns) do
    ~H"""
    <.input
      field={@field}
      label={translate("Password")}
      type="password"
      autocomplete={@autocomplete}
      required={@required}
      {@rest}
    />
    """
  end

  @doc """
  Renders a full-name input.

  ## Options

    * `:field` - form field to bind to this input (required).
    * `:required` - whether the field is required. Defaults to `false`.

  ## Styling

    * `[data-part="field"]` - input container.
    * `[data-part="label"]` - visible field label.
    * `[data-part="input"]` - form control.
    * `[data-invalid]` - invalid state on the container.

  ## Examples

      <EzAuth.UI.Core.Inputs.name field={@form[:name]} required />
  """
  attr(:field, FormField, required: true)
  attr(:required, :boolean, default: false)
  attr(:rest, :global)

  def name(assigns) do
    ~H"""
    <.input
      field={@field}
      label={translate("Name")}
      autocomplete="name"
      required={@required}
      {@rest}
    />
    """
  end

  @doc """
  Renders a polymorphic identity input that adapts label, type, inputmode, and
  autocomplete to whichever identity is currently active.

  Detection is the caller's responsibility — pass the active atom via `:identity`
  (typically computed from `EzAuth.Accounts.Identity.detect_identity/2` in the
  parent's `phx-change` handler). The underlying input carries `phx-debounce="150"`
  so the parent's change handler fires throttled. Before any identity is detected,
  the input's `name=` is the literal `"_identity"` (underscore-prefixed like
  Phoenix's `_target`), so submissions in the not-yet-detected state aren't
  treated as real form fields.

  ## Options

    * `:form` - the form to derive `name=` from once an identity is detected (required).
    * `:identity` - the active identity (`:email | :phone | nil`). Defaults to `nil`.
    * `:accepts` - identity types this input can adapt to. Defaults to `[:email]`.
    * `:field` - form field to bind value/errors to. Optional.
    * `:value` - current typed value. Optional.

  ## Examples

      <EzAuth.UI.Core.Inputs.identity form={@form} identity={@detected} accepts={[:email, :phone]} />
  """
  attr(:id, :string, required: true)
  attr(:form, Form, required: true)
  attr(:identity, :atom, required: true)
  attr(:accepts, :list, default: [:email])
  attr(:value, :string, default: nil)
  attr(:rest, :global)

  def identity(assigns) do
    assigns =
      assigns
      |> assign_new(:type, &identity_type(&1.identity))
      |> assign_new(:name, &identity_name(&1.form, &1.identity))
      |> assign_new(:label, &identity_label(&1.identity, &1.accepts))
      |> assign_new(:autocomplete, &identity_autocomplete(&1.identity))

    ~H"""
    <input
      :if={@identity}
      type="hidden"
      name={@name}
      value={@value}
    />
    <.input
      id={@id}
      name="_identity"
      value={@value}
      type={@type}
      inputmode={@type}
      label={@label}
      autocomplete={@autocomplete}
      {@rest}
    />
    """
  end

  @doc """
  Renders a row of single-character inputs for one-time code entry.

  Submits `name[0]`, `name[1]`, ... as separate params so the server can
  rejoin them. The `CodeInput` hook (in `priv/static/ez_auth.js`) handles
  auto-advance, Arrow/Backspace navigation, and paste distribution. Hosts
  must register the hook with their `LiveSocket`.

  ## Options

    * `:id` - unique id for the input group (required).
    * `:name` - base parameter name for the submitted code parts (required).
    * `:length` - number of boxes. Defaults to `6`.
    * `:format` - `:numeric` (digits only, default) or `:alphanumeric` (digits + letters).
      Gates the mask: the hook only advances focus when the typed character
      passes the mask.

  ## Styling

    * `[data-part="code-input"]` - code input container.
    * `[data-part="code-input-box"]` - each code entry box.
    * `[data-format={format}]` - active input mask on the container.

  ## Examples

      <EzAuth.UI.Core.Inputs.code id="verify-code" name="code" />
      <EzAuth.UI.Core.Inputs.code id="verify-code" name="code" length={4} />
      <EzAuth.UI.Core.Inputs.code id="verify-code" name="code" format={:alphanumeric} />
  """
  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:length, :integer, default: 6)
  attr(:format, :atom, default: :numeric, values: [:numeric, :alphanumeric])
  attr(:rest, :global)

  def code(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="CodeInput"
      data-part="code-input"
      data-format={@format}
      {@rest}
    >
      <input
        :for={i <- 0..(@length - 1)}
        type="text"
        name={"#{@name}[#{i}]"}
        inputmode={inputmode(@format)}
        maxlength="1"
        autocomplete="one-time-code"
        data-part="code-input-box"
      />
    </div>
    """
  end

  @doc """
  Renders a labelled input field.

  The shared building block used by all input components in this module.
  Accepts either a `Phoenix.HTML.FormField` (via `:field`) or raw
  `:id`/`:name`/`:value` attributes.

  ## Options

    * `:field` - bound form field. When given, `:id`, `:name`, `:value`,
      and `:errors` are derived from it.
    * `:id` - DOM id. Required when `:field` is not given.
    * `:name` - form name attribute. Required when `:field` is not given.
    * `:value` - current value. Defaults to `nil`.
    * `:label` - visible label text. Optional.
    * `:type` - one of `text`, `email`, `tel`, `password`. Defaults to `text`.
    * `:errors` - list of error messages. Defaults to `[]`.

  Extra attributes (`autocomplete`, `inputmode`, `placeholder`, etc.) are
  forwarded to the underlying `<input>`.

  ## Styling

    * `[data-part="field"]` - input container.
    * `[data-part="label"]` - visible field label.
    * `[data-part="input"]` - form control.
    * `[data-invalid]` - invalid state on the container.
  """
  attr(:id, :any, default: nil)
  attr(:name, :any)
  attr(:label, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:type, :string, default: "text", values: ~w(text email tel password))
  attr(:field, FormField)
  attr(:errors, :list, default: [])
  attr(:rest, :global, include: ~w(autocomplete disabled inputmode placeholder required))

  def input(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(:field, nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns[:name] || field.name)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &ErrorHelpers.translate_error/1))
    |> input()
  end

  def input(assigns) do
    assigns = assign(assigns, :invalid?, assigns.errors != [])

    ~H"""
    <div data-part="field" data-invalid={@invalid?}>
      <label :if={@label} for={@id} data-part="label">{@label}</label>
      <input
        type={@type}
        id={@id}
        name={@name}
        value={Form.normalize_value(@type, @value)}
        data-part="input"
        aria-invalid={@invalid?}
        aria-describedby={"#{@id}-error"}
        {@rest}
      />
      <Errors.message :for={msg <- @errors} id={"#{@id}-error"}>{msg}</Errors.message>
    </div>
    """
  end

  defp inputmode(:numeric), do: "numeric"
  defp inputmode(:alphanumeric), do: "text"

  defp identity_name(_form, nil), do: nil
  defp identity_name(form, identity), do: Form.input_name(form, identity)

  defp identity_type(nil), do: "text"
  defp identity_type(:email), do: "email"
  defp identity_type(:phone), do: "tel"

  defp identity_autocomplete(nil), do: "off"
  defp identity_autocomplete(:email), do: "email"
  defp identity_autocomplete(:phone), do: "tel"

  defp identity_label(nil, []), do: nil
  defp identity_label(nil, [:email]), do: translate("Email")
  defp identity_label(nil, [:phone]), do: translate("Phone")
  defp identity_label(nil, [:email, :phone]), do: translate("Email or phone")
  defp identity_label(nil, [:phone, :email]), do: translate("Email or phone")
  defp identity_label(:email, _accepts), do: translate("Continue with email")
  defp identity_label(:phone, _accepts), do: translate("Continue with phone")
end
