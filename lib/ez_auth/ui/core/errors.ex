defmodule EzAuth.UI.Core.Errors do
  @moduledoc """
  Error-rendering components.

  `message/1` renders errors for a single form field. `summary/1` renders
  a flow-level list for messages that don't belong to any single field.
  """

  use Phoenix.Component

  alias EzAuth.ErrorHelpers
  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.JS

  @doc """
  Renders errors for a form field.

  Pass either a form field or an `inner_block` slot with a message. Field
  errors only surface after the user has interacted with the field.

  ## Options

    * `:field` - form field whose visible errors should be rendered.
    * `:id` - unique id for the error message. Defaults to `"<field-id>-error"`
      when `:field` is set.

  ## Styling

    * `[data-part="error"]` - error message.

  ## Examples

      <EzAuth.UI.Core.Errors.message field={@form[:email]} />

      <EzAuth.UI.Core.Errors.message id="custom-error">
        Something went wrong
      </EzAuth.UI.Core.Errors.message>
  """
  attr(:field, FormField)
  attr(:id, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def message(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns =
      assigns
      |> assign(:field, nil)
      |> assign_new(:id, fn -> "#{field.id}-error" end)
      |> assign(:errors, Enum.map(errors, &ErrorHelpers.translate_error/1))

    ~H"""
    <p :for={msg <- @errors} id={@id} data-part="error" {@rest}>{msg}</p>
    """
  end

  def message(assigns) do
    ~H"""
    <p id={@id} data-part="error" {@rest}>{render_slot(@inner_block)}</p>
    """
  end

  @doc """
  Renders a flow-level error summary for messages that don't belong to a
  single field.

  Announced as an alert and takes focus on mount so keyboard users land
  on the summary after a failed submit.

  ## Options

    * `:errors` - list of error strings to display.

  ## Styling

    * `[data-part="error-summary"]` - error summary container.
    * `[data-part="error-summary-list"]` - error list.
    * `[data-part="error-summary-item"]` - each error item.

  ## Examples

      <EzAuth.UI.Core.Errors.summary errors={["Please complete all required fields"]} />
  """
  attr(:errors, :list, default: [])
  attr(:rest, :global)

  def summary(assigns) do
    ~H"""
    <div
      :if={@errors != []}
      data-part="error-summary"
      role="alert"
      tabindex="-1"
      phx-mounted={JS.focus()}
      {@rest}
    >
      <ul data-part="error-summary-list">
        <li :for={msg <- @errors} data-part="error-summary-item">{msg}</li>
      </ul>
    </div>
    """
  end
end
