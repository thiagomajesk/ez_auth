# EzAuth

EzAuth is an opinionated and batteries-included auth library inspired by PowAuth, Ueberauth, Clerk, BetterAuth and Supabase Auth.

## Key Features

- **⚡ Plug and Play**: Integrates easily with Phoenix so you can get auth up and running in no time.
- **🔋 Batteries Included**: Add a complete auth experience without piecing together every flow by hand.
- **🔐 Flexible Authentication**: Start simple and grow into the sign-in experience your product needs.
- **🎨 Customization**: Ship with pre-built components, then shape the experience to match your UI/UX.

## Installation

To install EzAuth, add it to your dependencies in `mix.exs`:


```elixir
def deps do
  [
    {:ez_auth, "~> 0.1.0"}
  ]
end
```

### Step 1 - Run the generator

Run the installer from your Phoenix application:

```bash
mix ez_auth.install
```

Then apply the generated migrations to your DB with `mix ecto.migrate`.

> NOTE: EzAuth generates migrations assuming PostgreSQL features by default (such as `citext`). You are free to adjust it to your needs as long as you don't drastically modify the core schema the library relies on.

### Step 2 - Add basic configuration

Start with a simple password authentication strategy:

```elixir
config :ez_auth,
  repo: MyApp.Repo,
  after_sign_in_path: "/",
  sign_in_path: "/sign-in",
  endpoint: MyAppWeb.Endpoint,
  gettext_backend: MyAppWeb.Gettext,
  strategies: [EzAuth.Strategies.Password]
```

> For provider-specific setup and strategy notes, see
> [`docs/STRATEGIES.md`](docs/STRATEGIES.md).

### Step 3 - Update your router

Add `use EzAuth` to your Router so the helpers are imported:

```diff
 defmodule MyAppWeb.Router do
   use MyAppWeb, :router
+  use EzAuth
```

Add `fetch_current_scope` to the browser pipeline:

```diff
 pipeline :browser do
   plug :accepts, ["html"]
   plug :fetch_session
   plug :fetch_live_flash
   plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
   plug :protect_from_forgery
   plug :put_secure_browser_headers
+  plug :fetch_current_scope
 end
```

Protect your routes:

```elixir
scope "/" do
  pipe_through :browser

  auth_routes()
end

 scope "/", MyAppWeb do
   pipe_through :browser

   live "/sign-in", SignInLive
   live "/sign-up", SignUpLive
 end

scope "/", MyAppWeb do
  pipe_through [:browser, :require_authenticated]

  get "/settings", SettingsController, :edit

  live_session :authenticated, on_mount: [{EzAuth, :require_authenticated}] do
    # All of your protected LiveView pages should go here :)
  end
end
```

> Do not place the `auth_routes` macro inside nested scopes, otherwise EzAuth's internal routes won't be properly picked up. Routes are hardcoded to overcome Phoenix's 1.8 new verified routes limitations requiring additional boilerplate code to make this work.

### Step 4 - Render the UI components

```elixir
defmodule MyAppWeb.SignInLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.live_component module={EzAuth.UI.SignIn} id="sign-in" />
    """
  end
end
```

```elixir
defmodule MyAppWeb.SignUpLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.live_component module={EzAuth.UI.SignUp} id="sign-up" />
    """
  end
end
```

## Custom behavior

Add these only when your app wants to customize message delivery or the HTTP response after EzAuth actions.

### Sender

To deliver verification or recovery messages yourself, configure a sender:

```diff
 config :ez_auth,
+  sender: MyApp.AuthSender
```

For example, the `:email` event is emitted when EzAuth creates an email verification token:

```elixir
defmodule MyApp.AuthSender do
  @behaviour EzAuth.Sender

  @impl true
  def deliver(:email, {_user, token}) do
    # Build this confirmation URL and deliver it to the user.
  end
end
```

### Handler

To customize success or failure responses, configure a handler:

```elixir
scope "/" do
  pipe_through :browser
  auth_routes(handler: MyAppWeb.AuthHandler)
end
```

You can then handle success and failure requests like this:

```elixir
defmodule MyAppWeb.AuthHandler do
  @behaviour EzAuth.Handler

  import Phoenix.Controller

  @impl true
  def handle_success(conn, {:default, :sign_up}, _user) do
    conn
    |> put_flash(:info, "Check your email to confirm your account.")
    |> redirect(to: EzAuth.Config.sign_in_path())
  end

  @impl true
  def handle_failure(conn, {:password, :request}, _reason) do
    conn
    |> put_flash(:error, "Invalid email or password.")
    |> redirect(to: EzAuth.Config.sign_in_path())
  end

  @impl true
  def handle_success(conn, {:password, :callback}, _user) do
    conn
    |> put_flash(:info, "Your email has been confirmed. You can sign in now.")
    |> redirect(to: EzAuth.Config.sign_in_path())
  end
end
```

## Components & Styling

EzAuth provides ready-to-use components such as `EzAuth.UI.SignIn` and `EzAuth.UI.SignUp` for the standard auth experience. If you need a custom flow, check the base components from `EzAuth.UI.Core` and `EzAuth.UI`. Additionally, you can build your own components with your own logic and simply use the helpers we provide.

EzAuth components are intentionally unstyled so they can adapt to any application. You add your own styles by targeting each component's `data-part` attributes. The default Storybook stylesheet in [`storybook/static/storybook.css`](storybook/static/storybook.css) is a good starting point if you want to see one complete styling approach. To see every available component and flow, run Storybook: `mix storybook`.
