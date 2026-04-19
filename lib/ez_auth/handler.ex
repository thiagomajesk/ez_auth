defmodule EzAuth.Handler do
  @moduledoc false

  @callback handle_success(
              conn :: struct(),
              action :: atom(),
              user :: struct()
            ) ::
              struct()

  @callback handle_failure(
              conn :: struct(),
              action :: atom(),
              reason :: term()
            ) ::
              struct()

  @optional_callbacks handle_success: 3, handle_failure: 3

  def maybe_invoke(conn, nil, _fun, _args), do: conn

  def maybe_invoke(conn, handler, fun, args) do
    arity = length(args) + 1

    if function_exported?(handler, fun, arity),
      do: apply(handler, fun, [conn | args]),
      else: conn
  end
end
