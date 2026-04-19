defmodule Storybook.Core.Buttons.Submit do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.Buttons.submit/1

  def variations do
    [
      %Variation{id: :default, attributes: %{}},
      %Variation{id: :custom_label, attributes: %{label: "Sign in"}}
    ]
  end
end
