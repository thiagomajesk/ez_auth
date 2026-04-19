defmodule Storybook.Core.Errors.Summary do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.Errors.summary/1

  def variations do
    [
      %Variation{
        id: :single,
        attributes: %{errors: ["Please complete all required fields"]}
      },
      %Variation{
        id: :multiple,
        attributes: %{
          errors: [
            "Email must be a valid email address",
            "Password must be at least 8 characters"
          ]
        }
      }
    ]
  end
end
