defmodule EzAuth.Storybook.Router do
  use Phoenix.Router
  use EzAuth
  import PhoenixStorybook.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, html: {PhoenixPlayground.Layout, :root})
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    storybook_assets()
  end

  scope "/" do
    pipe_through(:browser)
    live_storybook("/", backend_module: EzAuth.Storybook)
  end

  auth_routes()
end

defmodule EzAuth.Storybook.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_playground

  socket("/live", Phoenix.LiveView.Socket)
  socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)

  plug(Plug.Static,
    at: "/",
    from: Path.join(__DIR__, "static"),
    only: ~w(storybook.css storybook.js)
  )

  plug(Phoenix.LiveReloader)
  plug(Phoenix.CodeReloader)

  plug(Plug.Session,
    store: :cookie,
    key: "_ez_auth_storybook",
    signing_salt: "ez-auth-storybook"
  )

  plug(EzAuth.Storybook.Router)
end

defmodule EzAuth.Storybook do
  use PhoenixStorybook,
    otp_app: :ez_auth,
    content_path: __DIR__,
    title: "EzAuth.UI",
    css_path: "/storybook.css",
    js_path: "/storybook.js",
    sandbox_class: "ez-auth"

  def run do
    Application.put_all_env(
      ez_auth: [
        endpoint: EzAuth.Storybook.Endpoint,
        router: EzAuth.Storybook.Router,
        strategies: [
          EzAuth.Strategies.Password,
          EzAuth.Strategies.MagicLink,
          EzAuth.Strategies.SmsOtp,
          EzAuth.Strategies.Google
        ]
      ],
      phoenix_playground: [
        {EzAuth.Storybook.Endpoint, []}
      ],
      phoenix_live_reload: [
        dirs: [Path.expand("lib"), Path.expand("storybook")]
      ]
    )

    PhoenixPlayground.start(
      endpoint: EzAuth.Storybook.Endpoint,
      open_browser: false,
      live_reload: true,
      endpoint_options: [
        secret_key_base: String.duplicate("a", 64),
        live_reload: [
          patterns: [
            ~r"lib/ez_auth/.*\.(ex|heex)$",
            ~r"storybook/.*\.(ex|exs)$",
            ~r"storybook/static/.*\.(css|js)$"
          ]
        ]
      ]
    )
  end
end
