defmodule Storybook.Core.Inputs.Phone do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.Inputs.phone/1

  def imports, do: [{Storybook.InputHelpers, [sample_field: 1, sample_field: 2]}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{field: {:eval, ~s|sample_field(:phone)|}}
      },
      %Variation{
        id: :typed,
        attributes: %{
          field: {:eval, ~s|sample_field(:phone, value: "+15551234567")|}
        }
      },
      %Variation{
        id: :invalid,
        attributes: %{
          field:
            {:eval,
             ~s|sample_field(:phone, value: "abc", error: "is not a valid phone number")|}
        }
      }
    ]
  end
end
