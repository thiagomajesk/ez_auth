defmodule Storybook.Flows.TaskResetPassword do
  use PhoenixStorybook.Story, :live_component

  def component, do: EzAuth.UI.TaskResetPassword

  def imports, do: [{Storybook.InputHelpers, [sample_user: 0]}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{id: "reset-default", user: {:eval, ~s|sample_user()|}}
      }
    ]
  end
end
