defmodule Storybook.Core.Inputs.Poly do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.Inputs.poly/1

  def variations do
    [
      %Variation{
        id: :email_phone,
        description: "Email and phone",
        attributes: %{id: "poly-email-phone", accepts: [:email, :phone]}
      },
      %Variation{
        id: :email_only,
        description: "Email only",
        attributes: %{id: "poly-email-only", accepts: [:email]}
      },
      %Variation{
        id: :phone_only,
        description: "Phone only",
        attributes: %{id: "poly-phone-only", accepts: [:phone]}
      },
      %Variation{
        id: :detected_email,
        description: "Detected: email",
        attributes: %{id: "poly-detected-email", accepts: [:email, :phone], identity: :email}
      },
      %Variation{
        id: :detected_phone,
        description: "Detected: phone",
        attributes: %{id: "poly-detected-phone", accepts: [:email, :phone], identity: :phone}
      }
    ]
  end
end
