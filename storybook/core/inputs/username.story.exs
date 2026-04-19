defmodule Storybook.Core.Inputs.Username do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.Inputs.username/1

  def imports, do: [{Storybook.InputHelpers, [sample_field: 1, sample_field: 2]}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{field: {:eval, ~s|sample_field(:username)|}}
      },
      %Variation{
        id: :typed,
        attributes: %{
          field: {:eval, ~s|sample_field(:username, value: "alice")|}
        }
      },
      %Variation{
        id: :invalid,
        attributes: %{
          field:
            {:eval,
             ~s|sample_field(:username, value: "a", error: "must be at least 3 characters")|}
        }
      }
    ]
  end
end
