defmodule Storybook.Core.Inputs.Name do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.Inputs.name/1

  def imports, do: [{Storybook.InputHelpers, [sample_field: 1, sample_field: 2]}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{field: {:eval, ~s|sample_field(:name)|}}
      },
      %Variation{
        id: :typed,
        attributes: %{
          field: {:eval, ~s|sample_field(:name, value: "Alice Doe")|}
        }
      },
      %Variation{
        id: :invalid,
        attributes: %{
          field:
            {:eval, ~s|sample_field(:name, error: "can't be blank")|}
        }
      }
    ]
  end
end
