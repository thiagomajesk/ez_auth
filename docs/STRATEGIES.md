# Strategies

Strategies are the modules that implement each authentication flow in EzAuth. They define which identity they handle, how the request starts, and how the callback completes.

Every strategy follows the same lifecycle:

1. The request step starts the flow.
2. The user proves control of an identity.
3. The callback step verifies the proof and signs the user in.

Some strategies verify an existing pending identity by consuming an EzAuth verification token or code. Social strategies rely on the provider callback as the proof, then create or find a verified provider identity.

Each strategy section starts with:

- **Site:** the provider site where users authenticate.
- **Reference:** the main provider documentation for setup and behavior.
- **Module:** the EzAuth module to add to `:strategies`.

## Credential

### Password

- **Site:** N/A
- **Reference:** N/A
- **Module:** `EzAuth.Strategies.Password`

## Passwordless Strategies

### Magic Link

- **Site:** N/A
- **Reference:** N/A
- **Module:** `EzAuth.Strategies.MagicLink`

### Email OTP

- **Site:** N/A
- **Reference:** N/A
- **Module:** `EzAuth.Strategies.EmailOtp`

### SMS OTP

- **Site:** N/A
- **Reference:** N/A
- **Module:** `EzAuth.Strategies.SmsOtp`

## Social

### GitHub

Use GitHub when users should sign in with a GitHub OAuth App. GitHub verifies the user during the OAuth callback, then EzAuth creates or finds a verified `:github` identity for that provider user ID.

- **Site:** [GitHub](https://github.com)
- **Reference:** [Authorizing OAuth apps](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)
- **Module:** `EzAuth.Strategies.GitHub`

#### Setup

1. Create a GitHub OAuth App from GitHub's Developer settings.
   Follow GitHub's [Creating an OAuth app](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app)
   guide.
2. Set the application name and homepage URL to public-facing values for your
   host application.
3. Set the Authorization callback URL to your EzAuth GitHub callback route:
   `https://your-host.example/auth/github/callback`.
4. Save the app, then copy the Client ID and generate a Client Secret.
5. For local development, create a separate GitHub OAuth App with a local
   callback URL such as `http://localhost:4000/auth/github/callback`.
6. Review GitHub's [Web application flow](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#web-application-flow)
   and [Redirect URLs](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#redirect-urls)
   sections if GitHub rejects the callback URL.

#### Configuration

Add the GitHub strategy and read the OAuth credentials from environment variables:

```elixir
config :ez_auth,
  github_client_id: System.fetch_env!("GITHUB_CLIENT_ID"),
  github_client_secret: System.fetch_env!("GITHUB_CLIENT_SECRET"),
  strategies: [EzAuth.Strategies.Password, EzAuth.Strategies.GitHub]
```

Make sure your endpoint URL matches the public host GitHub redirects back to:

```elixir
config :my_app, MyAppWeb.Endpoint,
  url: [scheme: "https", host: "your-host.example", port: 443]
```

EzAuth uses that endpoint URL to build the OAuth callback URL it sends to GitHub.

#### Checklist

- The GitHub OAuth App callback URL exactly matches
  `/auth/github/callback` on your host.
- `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` are available in the runtime
  environment.
- `EzAuth.Strategies.GitHub` is included in `:strategies`.
- `auth_routes()` is mounted in your router so `/auth/github/request` and
  `/auth/github/callback` exist.
- The endpoint `:url` config uses the same scheme and host that users visit in
  the browser.

### Google

Use Google when users should sign in with a Google OAuth client. Google verifies
the user during the OAuth callback, then EzAuth creates or finds a verified
`:google` identity for the provider subject.

- **Site:** [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
- **Reference:** [OAuth 2.0 for Web Server Applications](https://developers.google.com/identity/protocols/oauth2/web-server)
- **Module:** `EzAuth.Strategies.Google`

#### Setup

1. Create or select a project in Google Cloud Console.
2. Configure the OAuth consent screen for the app.
3. Create an OAuth client ID for a web application.
4. Add your EzAuth Google callback route as an authorized redirect URI:
   `https://your-host.example/auth/google/callback`.
5. Copy the Client ID and Client Secret.

#### Configuration

```elixir
config :ez_auth,
  google_client_id: System.fetch_env!("GOOGLE_CLIENT_ID"),
  google_client_secret: System.fetch_env!("GOOGLE_CLIENT_SECRET"),
  strategies: [EzAuth.Strategies.Password, EzAuth.Strategies.Google]
```

#### Checklist

- The Google OAuth client redirect URI exactly matches
  `/auth/google/callback` on your host.
- `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are available in the runtime
  environment.
- `EzAuth.Strategies.Google` is included in `:strategies`.
- `auth_routes()` is mounted in your router.

### Microsoft

Use Microsoft when users should sign in with the Microsoft identity platform.
Microsoft verifies the user during the OAuth callback, then EzAuth creates or
finds a verified `:microsoft` identity for the provider user ID.

- **Site:** [Microsoft Entra admin center](https://entra.microsoft.com)
- **Reference:** [OAuth 2.0 authorization code flow](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow)
- **Module:** `EzAuth.Strategies.Microsoft`

#### Setup

1. Register an application in Microsoft Entra.
2. Add a web platform redirect URI for your EzAuth Microsoft callback route:
   `https://your-host.example/auth/microsoft/callback`.
3. Create a client secret for the app registration.
4. Copy the Application (client) ID and client secret value.
5. Confirm the app can request the `openid`, `email`, `profile`, and
   `User.Read` scopes.

#### Configuration

```elixir
config :ez_auth,
  microsoft_client_id: System.fetch_env!("MICROSOFT_CLIENT_ID"),
  microsoft_client_secret: System.fetch_env!("MICROSOFT_CLIENT_SECRET"),
  strategies: [EzAuth.Strategies.Password, EzAuth.Strategies.Microsoft]
```

#### Checklist

- The Microsoft app registration redirect URI exactly matches
  `/auth/microsoft/callback` on your host.
- `MICROSOFT_CLIENT_ID` and `MICROSOFT_CLIENT_SECRET` are available in the
  runtime environment.
- `EzAuth.Strategies.Microsoft` is included in `:strategies`.
- `auth_routes()` is mounted in your router.

### Apple

Use Apple when users should sign in with Sign in with Apple. Apple verifies the
user during the OAuth callback, then EzAuth verifies the returned ID token and
creates or finds a verified `:apple` identity for the provider subject.

- **Site:** [Apple Developer](https://developer.apple.com/account)
- **Reference:** [Sign in with Apple REST API](https://developer.apple.com/documentation/signinwithapplerestapi)
- **Module:** `EzAuth.Strategies.Apple`

#### Setup

1. Enable Sign in with Apple for your app in Apple Developer.
2. Create a Services ID for your web sign-in flow.
3. Add your EzAuth Apple callback route as the return URL:
   `https://your-host.example/auth/apple/callback`.
4. Create a Sign in with Apple private key.
5. Copy the Services ID, Team ID, Key ID, and private key.

#### Configuration

```elixir
config :ez_auth,
  apple_client_id: System.fetch_env!("APPLE_CLIENT_ID"),
  apple_team_id: System.fetch_env!("APPLE_TEAM_ID"),
  apple_key_id: System.fetch_env!("APPLE_KEY_ID"),
  apple_private_key: System.fetch_env!("APPLE_PRIVATE_KEY"),
  strategies: [EzAuth.Strategies.Password, EzAuth.Strategies.Apple]
```

#### Checklist

- The Apple Services ID return URL exactly matches `/auth/apple/callback` on
  your host.
- `APPLE_CLIENT_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, and `APPLE_PRIVATE_KEY`
  are available in the runtime environment.
- `EzAuth.Strategies.Apple` is included in `:strategies`.
- `auth_routes()` is mounted in your router.
