defmodule Storybook.Core.AuthForm do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.auth_form/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default",
        attributes: %{
          form: Phoenix.Component.to_form(%{}, as: nil),
          action: "/auth/sign-up",
          trigger_action: false,
          myself: nil
        },
        slots: ["<p>Form body slot.</p>"]
      }
    ]
  end
end
