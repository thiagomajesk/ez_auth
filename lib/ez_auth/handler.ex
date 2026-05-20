defmodule EzAuth.Handler do
  @moduledoc """
  Customizes HTTP responses after EzAuth actions.

  Configure a handler with `auth_routes(handler: MyAppWeb.AuthHandler)` when
  your Phoenix app needs to add flashes, redirect somewhere specific, or render
  a custom response after an authentication action.
  """

  @callback handle_success(
              conn :: struct(),
              event :: {module() | :default, atom()},
              user :: struct()
            ) ::
              struct()

  @callback handle_failure(
              conn :: struct(),
              event :: {module() | :default, atom()},
              reason :: term()
            ) ::
              struct()

  @optional_callbacks handle_success: 3, handle_failure: 3

  def maybe_invoke(conn, nil, _fun, _args), do: conn

  def maybe_invoke(conn, handler, fun, args) do
    arity = length(args) + 1

    if Code.ensure_loaded?(handler) and function_exported?(handler, fun, arity),
      do: apply(handler, fun, [conn | args]),
      else: conn
  end
end
