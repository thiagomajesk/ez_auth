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

- **Site:** N/A
- **Reference:** N/A
- **Module:** `EzAuth.Strategies.Google`

### Microsoft

- **Site:** N/A
- **Reference:** N/A
- **Module:** `EzAuth.Strategies.Microsoft`

### Apple

- **Site:** N/A
- **Reference:** N/A
- **Module:** `EzAuth.Strategies.Apple`
