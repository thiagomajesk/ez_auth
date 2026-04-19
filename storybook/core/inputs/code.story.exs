defmodule Storybook.Core.Inputs.Code do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.Inputs.code/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{id: "code-default", name: "code"}
      },
      %Variation{
        id: :four_digits,
        attributes: %{id: "code-four", name: "code", length: 4}
      },
      %Variation{
        id: :alphanumeric,
        attributes: %{id: "code-alnum", name: "code", format: :alphanumeric}
      }
    ]
  end
end
