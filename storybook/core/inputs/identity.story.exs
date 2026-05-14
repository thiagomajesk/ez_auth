defmodule Storybook.Identity do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.Inputs.identity/1

  def imports, do: [{Storybook.InputHelpers, [sample_form: 0]}]

  def variations do
    [
      %Variation{
        id: :email_phone,
        description: "Email and phone",
        attributes: %{
          id: "identity-email-phone",
          form: {:eval, "sample_form()"},
          identity: nil,
          accepts: [:email, :phone]
        }
      },
      %Variation{
        id: :email_only,
        description: "Email only",
        attributes: %{
          id: "identity-email-only",
          form: {:eval, "sample_form()"},
          identity: nil,
          accepts: [:email]
        }
      },
      %Variation{
        id: :phone_only,
        description: "Phone only",
        attributes: %{
          id: "identity-phone-only",
          form: {:eval, "sample_form()"},
          identity: nil,
          accepts: [:phone]
        }
      },
      %Variation{
        id: :detected_email,
        description: "Detected: email",
        attributes: %{
          id: "identity-detected-email",
          form: {:eval, "sample_form()"},
          identity: :email,
          accepts: [:email, :phone],
          value: "user@example.com"
        }
      },
      %Variation{
        id: :detected_phone,
        description: "Detected: phone",
        attributes: %{
          id: "identity-detected-phone",
          form: {:eval, "sample_form()"},
          identity: :phone,
          accepts: [:email, :phone],
          value: "+1234567"
        }
      }
    ]
  end
end
