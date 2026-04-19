defmodule Storybook.Flows.TaskForgotPassword do
  use PhoenixStorybook.Story, :live_component

  def component, do: EzAuth.UI.TaskForgotPassword

  def imports, do: [{Storybook.InputHelpers, [sample_user: 0]}]

  def variations do
    [
      %Variation{
        id: :default,
        description: "Email entry",
        attributes: %{id: "forgot-default", email: nil}
      },
      %Variation{
        id: :default_with_email,
        description: "Email entry (prefilled)",
        attributes: %{id: "forgot-default-prefilled", email: "user@example.com"}
      },
      %Variation{
        id: :request,
        description: "Request sent",
        attributes: %{id: "forgot-request", email: "user@example.com", step: :request}
      },
      %Variation{
        id: :verify,
        description: "Verify code",
        attributes: %{id: "forgot-verify", email: "user@example.com", step: :verify}
      },
      %Variation{
        id: :reset,
        description: "Reset password",
        attributes: %{
          id: "forgot-reset",
          email: "user@example.com",
          step: :reset,
          user: {:eval, ~s|sample_user()|}
        }
      }
    ]
  end
end
