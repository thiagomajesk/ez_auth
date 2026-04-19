defmodule Storybook.Core.Inputs.Email do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.Inputs.email/1

  def imports, do: [{Storybook.InputHelpers, [sample_field: 1, sample_field: 2]}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{field: {:eval, ~s|sample_field(:email)|}}
      },
      %Variation{
        id: :typed,
        attributes: %{
          field: {:eval, ~s|sample_field(:email, value: "user@example.com")|}
        }
      },
      %Variation{
        id: :invalid,
        attributes: %{
          field:
            {:eval,
             ~s|sample_field(:email, value: "not-an-email", error: "must be a valid email")|}
        }
      }
    ]
  end
end
