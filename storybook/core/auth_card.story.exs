defmodule Storybook.Core.AuthCard do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.auth_card/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default",
        attributes: %{
          title: "Sign in to your account",
          subtitle: "Welcome back! Please sign in to continue."
        },
        slots: [
          "Card content goes here.",
          ~s|<:footer>Don't have an account? <a href="#" data-part="footer-link">Sign up</a></:footer>|
        ]
      },
      %Variation{
        id: :sign_up_copy,
        description: "Sign-up copy",
        attributes: %{
          title: "Create your account",
          subtitle: "Welcome! Please fill in the details to get started."
        },
        slots: [
          "Card content goes here.",
          ~s|<:footer>Already have an account? <a href="#" data-part="footer-link">Sign in</a></:footer>|
        ]
      }
    ]
  end
end
