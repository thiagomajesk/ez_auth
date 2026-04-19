defmodule Storybook.Core.Inputs.Password do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.Inputs.password/1

  def imports, do: [{Storybook.InputHelpers, [sample_field: 1, sample_field: 2]}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{field: {:eval, ~s|sample_field(:password)|}}
      },
      %Variation{
        id: :typed,
        attributes: %{
          field: {:eval, ~s|sample_field(:password, value: "correct horse battery")|}
        }
      },
      %Variation{
        id: :invalid,
        attributes: %{
          field:
            {:eval,
             ~s|sample_field(:password, value: "x", error: "must be at least 8 characters")|}
        }
      }
    ]
  end
end
