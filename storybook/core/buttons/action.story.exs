defmodule Storybook.Core.Buttons.Action do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.Buttons.action/1

  def variations do
    [
      %Variation{
        id: :just_icon,
        description: "Just icon",
        attributes: %{icon: :arrow_right}
      },
      %Variation{
        id: :icon_and_label,
        description: "Icon and label",
        attributes: %{icon: :envelope, label: "Resend invite"}
      },
      %Variation{
        id: :no_icon,
        description: "No icon",
        attributes: %{label: "Save"}
      }
    ]
  end
end
