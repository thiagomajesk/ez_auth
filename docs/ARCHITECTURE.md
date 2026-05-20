# Architecture

EzAuth supports multiple strategies, and keeps a small public API. The library draws inspiration from Clerk's developer experience, Better Auth and Supabase's ergonomics, and Phoenix's auth convention/semantics.

## Database

EzAuth manages the following tables under the `auth` schema/prefix:

### Users

The auth principal. Holds the user's profile (name, username, metadata) alongside the password credential. Profile fields are not collected by the standard sign-up flow; see [Profile](#profile) below.

| column | type | notes |
|---|---|---|
| `id` | bigint PK | auto-generated surrogate key |
| `name` | string, nullable | display name |
| `username` | citext, nullable, unique | profile alias; not a sign-in identifier on its own |
| `hashed_password` | string, nullable | Bcrypt hash; nullable for passwordless users |
| `metadata` | jsonb, NOT NULL, default `{}` | host-defined profile data; see Profile |
| `anonymous` | boolean, NOT NULL, default false | marks anonymous/guest accounts |
| `inserted_at` | utc_datetime | record creation timestamp |
| `updated_at` | utc_datetime | record update timestamp |

### Identities

Ways a user is known. Multi-valued: a user may have several emails or phones, and unverified duplicate claims may coexist until one verifies.

| column | type | notes |
|---|---|---|
| `id` | bigint PK | auto-generated surrogate key |
| `user_id` | bigint FK -> users, NOT NULL, cascade | owning user |
| `provider` | string, NOT NULL | provider namespace (`"email"`, `"phone"`, `"apple"`, `"github"`, `"google"`, `"microsoft"`, or a host-defined provider) |
| `value` | citext, NOT NULL | the email, phone, or provider identity string |
| `verified_at` | utc_datetime, nullable | set when ownership proof completes |
| `inserted_at` | utc_datetime | record creation timestamp |
| `updated_at` | utc_datetime | record update timestamp |

### Sessions

Authenticated sessions. Opaque tokens stored server-side and referenced by cookie.

| column | type | notes |
|---|---|---|
| `id` | bigint PK | auto-generated surrogate key |
| `user_id` | bigint FK -> users, NOT NULL, cascade | owning user |
| `token` | binary, NOT NULL, unique | raw session token bytes; the encoded token lives in the cookie |
| `expires_at` | utc_datetime, NOT NULL | hard expiry after which the session is invalid |
| `inserted_at` | utc_datetime | record creation timestamp |
| `updated_at` | utc_datetime | record update timestamp |

### Verifications

Single-use challenges tied to an auth flow. Immutable after insert, except that requesting a new challenge for the same user, type, and value replaces the old challenge.

| column | type | notes |
|---|---|---|
| `id` | bigint PK | auto-generated surrogate key |
| `user_id` | bigint FK -> users, NOT NULL, cascade | owning user |
| `type` | Ecto.Enum, NOT NULL | verification kind: `:email`, `:phone`, `:recovery`, `:email_change`, `:phone_change` |
| `token` | string, NOT NULL, unique | SHA-256 hash of the raw token or code |
| `value` | string, nullable | flow-specific payload (e.g., the email being verified) |
| `expires_at` | utc_datetime, NOT NULL | hard expiry after which the token is invalid |
| `inserted_at` | utc_datetime, NOT NULL | record creation timestamp; no `updated_at` since rows are immutable |

## Structure

* `lib/ez_auth.ex`: top-level integration surface (route macros, LiveView on_mount, use macro)
* `lib/ez_auth/`: core modules (accounts, auth, config, dispatcher, handler, sender, strategy, error_helpers)
* `lib/ez_auth/accounts/`: Ecto schemas and persistence helpers (user, identity, session, token, verification)
* `lib/ez_auth/strategies/`: authentication strategy implementations and placeholders (password, magic link, email OTP, SMS OTP, WhatsApp, Apple, GitHub, Google, Microsoft)
* `lib/ez_auth/scopes/`: context structs passed through the auth pipeline (user scope, sender scope)
* `lib/ez_auth/ui/`: unstyled LiveComponents and function components for sign-in, sign-up, verification, recovery, and reset flows

### Boundaries

* `EzAuth`: the entry point host apps interact with. Provides route macros (`auth_routes/1`), LiveView `on_mount/4` hooks, and a `__using__` macro that imports auth helpers into router modules. Nothing in this module touches persistence directly.

* `EzAuth.Accounts`: the stable public boundary for auth domain operations. User creation and lookup, profile updates, session token generation and revocation, verification issuance and consumption. Verification functions also dispatch delivery through the configured `EzAuth.Sender` behaviour. All session and verification details are exposed as semantic operations, never as raw persistence calls.

* `EzAuth.Auth`: the web/connection layer. Manages session cookies, assigns the current authenticated scope to conn requests, and provides plug-level guards (`require_authenticated`, `redirect_if_authenticated`). `sign_in_user/2` is the standard entrypoint for creating sessions from HTTP and LiveView flows. This module calls into `Accounts` for token storage but never bypasses it.

* `Strategies`: self-contained flow orchestrators. Each strategy uses `EzAuth.Strategy` with stable metadata (`:provider`, `:name`, `:identity`, `:kind`, and `:callback_methods`), handles request/callback parsing, and decides which auth flow is being executed. Routes are derived from the strategy provider: each strategy gets `POST /auth/:strategy/request` and one or more `/auth/:strategy/callback` routes. Strategies call `Accounts` for user lookups and verification, and `Auth` for session creation. They do not own sign-up, session persistence, or verification state. The dispatcher routes strategy outcomes to host-app callbacks defined by the `EzAuth.Handler` behaviour.

* `EzAuth.Accounts.*` (User, Identity, Session, Token, Verification): internal Ecto schemas and persistence helpers. These modules support `Accounts`; host apps should call the public `Accounts` boundary instead.

## Auth Flow

### Sign-up

Sign-up is **email + password only**. Passwordless flows (`magic_link`, `sms_otp`, `whatsapp`) do not have a separate sign-up surface; implemented passwordless flows create the user during the request step when needed (see "Passwordless creates on demand" below).

1. Validate email + password
2. Create user, attach unverified email identity, dispatch email verification

```
Dispatcher.sign_up/2
├── Accounts.create_user_with_password/1
├── Accounts.request_email_verification_link/1
└── Handler.handle_success/3
```

The user, their email identity, and a verification token are created together. The raw token is never returned to the caller; it dispatches out-of-band through the configured `EzAuth.Sender`. Password confirmation URLs point at `/auth/password/callback?token=...`.

### Passwordless creates on demand

`MagicLink.request/2` and `EmailOtp.request/2` look up the requested identity through `Accounts.find_or_create_email_identity/1`. If a verified identity exists, they reuse it. If not, the helper inserts a fresh passwordless user plus an unverified identity, and the strategy issues the verification. There is no separate flag: enabling an implemented passwordless strategy is the opt-in. Hosts that want sign-in only must keep those strategies disabled (or wrap the request route with their own access check).

`SmsOtp` and `Whatsapp` are currently registered metadata placeholders. Their default strategy actions fail closed until implemented.

### Sign-in

#### Password

1. Look up user by identity and verify password
2. Create session (or reject on mismatch)

```
Dispatcher.request/2
├── EzAuth.Strategies.Password.request/2
└── Handler.handle_success/3
```

The password strategy looks up the user by their verified email identity, then verifies the password hash. On success it delegates to `Auth.sign_in_user/2`, which generates the token, sets the session cookie, and assigns a live socket ID for LiveView disconnect broadcasts. Password is anchored to email; phone + password and username + password are not supported.

##### Confirmation

```
Dispatcher.callback/2
├── EzAuth.Strategies.Password.callback/2
└── Handler.handle_success/3
```

The password callback consumes the email verification token and marks the email identity as verified without signing the user in. This callback returns the connection unchanged on success, so hosts that expose it must implement `handle_success/3` for `{EzAuth.Strategies.Password, :callback}` to send a response.

#### Magic link

1. Look up user by email and send magic link
2. Consume token, verify email, and create session

##### Request

```
Dispatcher.request/2
├── EzAuth.Strategies.MagicLink.request/2
└── Handler.handle_success/3
```

The request action does not create a session. It issues a verification token and dispatches it through the sender. The user is not signed in until they click the link and hit the callback action. This action returns the connection unchanged on success, so hosts that expose it must implement `handle_success/3` for `{EzAuth.Strategies.MagicLink, :request}` to send a response.

##### Callback

```
Dispatcher.callback/2
├── EzAuth.Strategies.MagicLink.callback/2
└── Handler.handle_success/3
```

Consuming the token both authenticates the user and marks their email identity as verified if it wasn't already. This means clicking a magic link doubles as email confirmation for that strategy.

### Sign-out

1. Revoke session token and disconnect live sessions
2. Clear cookie when a token exists and redirect

```
Dispatcher.sign_out/2
├── Auth.sign_out_user/2
└── Handler.handle_success/3
```

Sign-out revokes the current session token and broadcasts a disconnect to any LiveView socket tied to it, so real-time UIs reflect the sign-out immediately instead of waiting for the next request cycle. If there is no `:user_token`, EzAuth still redirects to the sign-in path but leaves unrelated session keys untouched.

### Session

`Auth.fetch_current_scope/2` is called on HTTP requests via the plug pipeline to load the authenticated user from the session cookie. LiveViews load the same scope through `EzAuth.on_mount/4`. If the token is invalid, expired, or no longer maps to a user, the scope is set to nil and the stale session key is left in place.

`Accounts.revoke_user_sessions/1` invalidates all sessions for a user at once. Host apps should call it after password changes or other sensitive credential updates, typically paired with `Auth.disconnect_sessions/2` to broadcast disconnects to live sockets for the revoked tokens.

## Design Notes

### Security

* Passwords are hashed with Bcrypt and stored in `users.hashed_password`. The schema's plaintext `:password` and `:password_confirmation` fields are virtual and marked `redact: true`, so they never appear in logs or debug output and never reach the database.

* Verification tokens are hashed with SHA-256 before being stored in `verifications.token`. The raw token only exists in memory at creation time, so it can be sent out-of-band. The public API never returns the raw token, and it's never persisted.

* When you request a new verification link for the same user, type, and target (like the same email address), the old link is replaced and becomes invalid. Only the most recent link is valid; this avoids confusion when users request multiple links in a row.

* When a verification token is used, the database row is deleted immediately. A later reuse fails with `{:error, :invalid_token}`. The type is also checked on use (email, recovery, etc.) so a token from one flow can never be consumed in another.

* Session tokens are stored as raw bytes; verification tokens are stored as SHA-256 hashes. The difference tracks where each token travels. Session tokens stay inside a signed HTTP-only cookie, so the database row and the cookie share the same trust boundary; hashing the row would not add protection against anything the cookie doesn't already cover. Verification tokens travel out-of-band through email or SMS, so the stored row and the delivered token live on different trust boundaries, and hashing is what keeps a leaked row from becoming a usable token. EzAuth stays compatible with `mix phx.gen.auth`'s split here on purpose.

* The LiveView disconnect topic is `"auth_sessions:" <> <Base64 session token>`, kept compatible with `mix phx.gen.auth`'s `live_socket_id` convention. `Auth.disconnect_sessions/2` uses this shape to broadcast disconnects when sessions are revoked. Because the topic contains a live session token, anything that logs PubSub topics (LiveView debug logs, telemetry, external backends) will capture it. Scrub PubSub topic names from your log sinks; this is operational hygiene inherited from the Phoenix convention, not a library defect.

* Strategies return specific error reasons like `:invalid_credentials` when it helps tests or handlers decide what to do. Preventing account enumeration is a UI concern: whatever layer turns a reason into a user-visible response must normalize enumerable outcomes into generic messages ("invalid credentials", "check your email"). Strategies hand typed reasons to `EzAuth.Handler` callbacks precisely so the UI layer can decide the messaging; exposing the raw reason to end users is what causes the leak, not the existence of the reason itself.

### Identities

* Only verified identities count as taken. Multiple people can sign up with the same email or phone while it's unverified; whoever verifies first claims the identity. Later verification attempts for the same value fail with `{:error, :already_claimed}`, and signing up against an already-verified value is rejected upfront. This avoids identity parking: an abandoned sign-up or malicious reservation cannot permanently block the real owner of an email or phone.

* If sender delivery fails after sign-up, the user might be locked out because they never received the initial verification email and cannot request a new verification link through password recovery. Recovery only works for verified identities, so the system needs to handle delivery retries on its own.

* EzAuth does not clean up unverified identities left behind by abandoned sign-ups, failed deliveries, or verification races. Your system should clean up stale unverified identities and their users so the real owner can sign up again and receive a fresh verification link. EzAuth does not pick the cleanup policy for the host because retention windows, sender reliability, and abuse controls vary by app.

* Usernames live on `users.username` with a database-level unique constraint; there is no verification step for them.

* Email verification and email magic-link sign-in use the same trust boundary: control of the inbox proves both ownership and authentication. The password strategy uses email verification without sign-in; the magic-link strategy verifies email and creates a session in one step.

* Once an identity is verified, the user can sign in with any enabled implemented strategy that uses that identity provider. For example, a verified email can be used for password login or magic link. Verification proves the user controls the identity; strategies define the ways to authenticate with it. If you need stricter rules (e.g., "verification only, no magic link"), enforce them in your app.

* Phone identities must be in E.164 format (e.g., `+15551234567`). EzAuth validates the format with the regex `^\+[1-9]\d{1,14}$`; anything else fails validation. The library won't try to parse friendly formats like `(555) 123-4567` because country and UX context varies. Normalize phone input in your app before passing it to EzAuth.

### Profile

* Profile fields (`name`, `username`, `metadata`) are not collected by the standard sign-up flow. EzAuth's UI and changesets only collect what's needed to authenticate: email + password for the password strategy, the appropriate identifier for passwordless. This avoids the uniqueness-reservation lifecycle a "complete your profile at sign-up" flow would introduce, especially for OAuth where providers vary in what they return.

* Hosts collect profile data on their own terms via `Accounts.update_user_profile/2`, typically in a post-login step. The function casts `:name`, `:username`, and `:metadata` through `User.profile_changeset/2` and reuses the same format/length rules configured under `EzAuth.Config.name_format/0`, `EzAuth.Config.username_format/0`, etc.

* `users.username` keeps its unique index. The changeset performs an optimistic availability check via `Accounts.username_taken?/1`; the database-level unique constraint is the source of truth, and a conflict at insert time is what the host repairs.

### Sessions

* When a user changes their password or an admin locks them out, the host app must revoke all their sessions and disconnect any open pages. EzAuth provides two primitives: `Accounts.revoke_user_sessions/1` deletes all session tokens from the database and returns them; `Auth.disconnect_sessions/2` takes the endpoint and token list and broadcasts disconnect messages to their LiveView sockets. Call both in sequence: tokens stop working immediately, and users see the sign-out without waiting for the next request. They're separate by design: the host controls *when* revocation happens based on its own business logic.

* `UI.TaskResetPassword` always revokes every session for the user and broadcasts disconnect on a successful reset. No opt-out. Recovery flows usually run because the user suspects compromise, so a reset that leaves prior sessions live defeats the point. Hosts wiring their own settings-style password change should default to the same.

* `Auth.sign_out_user/2` redirects to the sign-in path in every branch. When there's no `:user_token` in the conn's session at all, it redirects without `renew_session/0`, so unrelated session keys remain. When the token is invalid or revoked, it renews and clears the session before redirecting.

* EzAuth has no user-delete function: host apps delete users through their own code. Cascade foreign keys handle the child rows (identities, sessions, verifications), so no orphaned auth data remains. Cascade is DB-only though: it won't disconnect open LiveView sockets. If you need to force an in-flight user offline, call `revoke_user_sessions/1` + `disconnect_sessions/2` (see above) before deleting.

### Misc

* EzAuth only enforces password length bounds (`password_min_length` and `password_max_length`). It does not check passwords against breach lists, dictionaries, or context-specific weak values. If you want that protection, validate passwords in your app before calling the sign-up flow.

* The default `password_min_length` is 8, a deliberately low, configurable floor. The default `password_max_length` is 72 (bcrypt's practical limit). If your threat model needs a higher minimum (or a passphrase flow), override `password_min_length` in `EzAuth.Config`. This is a policy knob, not a security default the library is taking a position on; ASVS-L1's 12-character minimum and NIST SP 800-63B-4's 15-character recommendation are both reachable by setting the config value: picking them for every host would be a policy choice the library is explicitly avoiding.

* Rate limiting and resend cooldowns are intentionally not built into EzAuth. Useful limits are application-specific: they depend on your app's identity strategy, which action is being protected, your storage backend, sender cost, and escalation rules. Implement them in your app. EzAuth may revisit this if a small, policy-neutral integration hook becomes feasible.
