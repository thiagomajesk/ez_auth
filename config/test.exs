import Config

config :bcrypt_elixir, :log_rounds, 1

config :ez_auth, EzAuth.TestRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ez_auth_test#{System.get_env("MIX_TEST_PARTITION")}",
  priv: "priv/repo",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :ez_auth, ecto_repos: [EzAuth.TestRepo]

config :ez_auth, EzAuth.Test.Endpoint,
  secret_key_base: String.duplicate("a", 64),
  server: false

config :ez_auth,
  repo: EzAuth.TestRepo,
  endpoint: EzAuth.Test.Endpoint,
  gettext_backend: EzAuth.TestGettext,
  strategies: [EzAuth.Strategies.Password, EzAuth.Strategies.MagicLink]

config :logger, level: :warning
