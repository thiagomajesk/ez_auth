defmodule Storybook.Flows.SignIn do
  use PhoenixStorybook.Story, :live_component

  alias EzAuth.Strategies

  def component, do: EzAuth.UI.SignIn

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default",
        attributes: %{id: "sign-in-default"}
      },
      %Variation{
        id: :password_only,
        description: "Password only",
        attributes: %{
          id: "sign-in-password",
          strategies: [Strategies.Password]
        }
      },
      %Variation{
        id: :magic_link_only,
        description: "Magic link only",
        attributes: %{
          id: "sign-in-magic-link",
          strategies: [Strategies.MagicLink]
        }
      },
      %Variation{
        id: :sms_otp_only,
        description: "SMS OTP only",
        attributes: %{
          id: "sign-in-sms",
          strategies: [Strategies.SmsOtp]
        }
      },
      %Variation{
        id: :password_and_magic_link,
        description: "Password + magic link",
        attributes: %{
          id: "sign-in-pw-magic",
          strategies: [Strategies.Password, Strategies.MagicLink]
        }
      },
      %Variation{
        id: :passwordless,
        description: "Passwordless only",
        attributes: %{
          id: "sign-in-passwordless",
          strategies: [Strategies.MagicLink, Strategies.EmailOtp, Strategies.SmsOtp]
        }
      },
      %Variation{
        id: :many_options,
        description: "Many options",
        attributes: %{
          id: "sign-in-many",
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
