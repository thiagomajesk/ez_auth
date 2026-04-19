defmodule Storybook.InputHelpers do
  @moduledoc false

  # Builds a `Phoenix.HTML.FormField` for input variations. Pass `:value`
  # to demonstrate the typed state, and `:error` to demonstrate the
  # invalid state. Sets `params` so `Phoenix.Component.used_input?/1`
  # returns true and the error renders.
  def sample_field(name, opts \\ []) do
    value = Keyword.get(opts, :value, "")
    error = Keyword.get(opts, :error)
    errors = if error, do: [{name, {error, []}}], else: []

    Phoenix.Component.to_form(
      %{to_string(name) => value},
      as: :user,
      errors: errors
    )[name]
  end

  # Returns a placeholder `%EzAuth.Accounts.User{}` for variations that
  # need a user attribute, without dumping the full struct into the docs.
  def sample_user, do: %EzAuth.Accounts.User{}
end
