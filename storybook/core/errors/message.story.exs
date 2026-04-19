defmodule Storybook.Core.Errors.Message do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.Errors.message/1

  def variations do
    [
      %Variation{
        id: :basic,
        attributes: %{id: "field-error"},
        slots: ["This field is required"]
      }
    ]
  end
end
