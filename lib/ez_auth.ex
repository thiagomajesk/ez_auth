defmodule EzAuth do
  @moduledoc """
  Top-level Phoenix and LiveView integration for EzAuth.
  """

  import EzAuth.Translations, only: [translate: 1]

  alias EzAuth.Config
  alias EzAuth.Scopes.UserScope

  def on_mount(:assign_current_scope, _params, session, socket) do
    {:cont, assign_current_scope(socket, session)}
  end

  def on_mount(:require_authenticated, _params, session, socket) do
    socket = assign_current_scope(socket, session)

    if get_in(socket.assigns.current_scope.user) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, translate("You must log in to access this page."))
        |> Phoenix.LiveView.redirect(to: Config.sign_in_path())

      {:halt, socket}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import EzAuth.Auth,
        only: [
          fetch_current_scope: 2,
          require_authenticated: 2,
          redirect_if_authenticated: 1
        ]

      import EzAuth, only: [auth_routes: 0, auth_routes: 1]
    end
  end

  defmacro auth_routes(opts \\ []) do
    handler = Keyword.get(opts, :handler)
    prefix = Keyword.get(opts, :prefix, "/auth")
    strategies = EzAuth.Strategy.supported_strategies()

    quote do
      EzAuth.__validate_scope__!(__MODULE__)

      scope unquote(prefix), alias: false, as: false do
        for strategy <- unquote(strategies) do
          slug = EzAuth.Strategy.slug(strategy)

          post("/#{slug}/request", EzAuth.Dispatcher, :request,
            as: EzAuth.Strategy.helper(strategy, :request),
            private: %{ez_auth: %{strategy: strategy, handler: unquote(handler)}}
          )

          post("/#{slug}/callback", EzAuth.Dispatcher, :callback,
            as: EzAuth.Strategy.helper(strategy, :callback),
            private: %{ez_auth: %{strategy: strategy, handler: unquote(handler)}}
          )
        end

        post("/sign-up", EzAuth.Dispatcher, :sign_up,
          as: :ez_auth_sign_up,
          private: %{ez_auth: %{handler: unquote(handler)}}
        )

        delete("/sign-out", EzAuth.Dispatcher, :sign_out,
          as: :ez_auth_sign_out,
          private: %{ez_auth: %{handler: unquote(handler)}}
        )
      end
    end
  end

  def __validate_scope__!(module) do
    if Enum.any?(scopes(module), &problematic?/1) do
      IO.warn("""
      auth_routes/1 was invoked inside a scope that sets `:path`, `:alias`, or `:as`.
      ez_auth mounts its own scope internally (see the `:prefix` option), resets
      `:alias` and `:as` to keep helper names stable, and owns its controllers.
      Any outer values are either ignored or produce a double prefix.

      Remove the wrapping scope, or keep only `pipe_through` inside `scope "/"`.
      Use `auth_routes(prefix: "/custom")` to change the mount point.
      """)
    end
  end

  defp scopes(module) do
    List.wrap(
      Module.get_attribute(module, :phoenix_top_scopes) ||
        Module.get_attribute(module, :phoenix_router_scopes)
    )
  end

  defp problematic?(%{path: p, alias: a, as: as}) do
    p not in [nil, "", "/", []] or a not in [nil, []] or as not in [nil, []]
  end

  defp assign_current_scope(socket, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      case EzAuth.Accounts.get_user_by_session_token(session["user_token"]) do
        :error -> nil
        user -> UserScope.new(user)
      end
    end)
  end
end
