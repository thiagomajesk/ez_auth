defmodule Storybook.Flows.TaskVerifyAccount do
  use PhoenixStorybook.Story, :live_component

  def component, do: EzAuth.UI.TaskVerifyAccount

  def variations do
    [
      %Variation{id: :default, attributes: %{id: "verify-default"}},
      %Variation{
        id: :with_identity,
        attributes: %{id: "verify-identity", identity: "user@example.com"}
      }
    ]
  end
end
