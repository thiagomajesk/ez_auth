import Config

config :phoenix_playground, EzAuth.Storybook.Endpoint, debug_errors: true

config :ez_auth,
  repo: EzAuth.Storybook.Endpoint,
  sender: EzAuth.Storybook.Endpoint,
  endpoint: EzAuth.Storybook.Endpoint,
  router: EzAuth.Storybook.Router,
  strategies: [
    EzAuth.Strategies.Password,
    EzAuth.Strategies.MagicLink,
    EzAuth.Strategies.EmailOtp,
    EzAuth.Strategies.SmsOtp,
    EzAuth.Strategies.Apple,
    EzAuth.Strategies.Google,
    EzAuth.Strategies.GitHub,
    EzAuth.Strategies.Microsoft
  ]
