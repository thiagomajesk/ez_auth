defmodule EzAuth.ErrorHelpers do
  @moduledoc """
  Translation helpers for changeset errors.

  Uses the Gettext backend configured under the `:ez_auth, :gettext_backend` Application env.
  """

  import EzAuth.Translations, only: [translate: 3]

  @doc """
  Translates a single `{message, opts}` error tuple.

  Routes through the configured Gettext backend.
  """
  def translate_error({msg, opts}) do
    translate(msg, opts, opts[:count] || 1)
  end

  @doc """
  Translates every `{message, opts}` error for the given field.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
