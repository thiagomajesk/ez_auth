defmodule Storybook.Flows.SignUp do
  use PhoenixStorybook.Story, :live_component

  alias EzAuth.Strategies

  def component, do: EzAuth.UI.SignUp

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default",
        attributes: %{id: "sign-up-default"}
      },
      %Variation{
        id: :password_strategy,
        description: "Password strategy",
        attributes: %{
          id: "sign-up-password",
          strategies: [Strategies.Password]
        }
      },
      %Variation{
        id: :magic_link_and_sms,
        description: "Magic link + SMS",
        attributes: %{
          id: "sign-up-magic-sms",
          strategies: [Strategies.Password, Strategies.MagicLink, Strategies.SmsOtp]
        }
      },
      %Variation{
        id: :passwordless_only,
        description: "Passwordless only",
        attributes: %{
          id: "sign-up-passwordless",
          strategies: [Strategies.MagicLink, Strategies.EmailOtp, Strategies.SmsOtp]
        }
      },
      %Variation{
        id: :many_options,
        description: "Many options",
        attributes: %{
          id: "sign-up-many",
          strategies: [
            Strategies.Password,
            Strategies.MagicLink,
            Strategies.EmailOtp,
            Strategies.SmsOtp,
            Strategies.Google,
            Strategies.Apple,
            Strategies.GitHub
          ]
        }
      }
    ]
  end
end
