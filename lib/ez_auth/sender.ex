defmodule EzAuth.Sender do
  @moduledoc """
  Behaviour for delivering out-of-band authentication messages.
  """

  require Logger

  @doc """
  Delivers an auth message for the given event and scope.

  When sender delivery fails with `{:error, reason}`, it does not abort the auth flow.
  The result is propagated normally and may be handled by the configured handler via `handle_failure/3`.
  """
  @callback deliver(event :: atom(), scope :: struct()) ::
              :ok | {:error, term()}

  def maybe_invoke(nil, _event, _scope), do: :ok

  def maybe_invoke(sender, event, scope) do
    if Code.ensure_loaded?(sender) and function_exported?(sender, :deliver, 2),
      do: sender.deliver(event, scope),
      else: log_skipped_call(sender, event, scope)
  end

  defp log_skipped_call(sender, event, scope) do
    Logger.info("""
    EzAuth sender #{inspect(sender)} does not implement deliver/2.
    Skipped #{inspect(event)} delivery for #{inspect(scope)}.
    """)
  end
end
