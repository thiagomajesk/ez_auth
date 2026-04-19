defmodule Storybook.Core.Buttons.Strategy do
  use PhoenixStorybook.Story, :component

  alias EzAuth.Strategies

  def function, do: &EzAuth.UI.Core.Buttons.strategy/1

  def variations do
    for strategy <- [
          Strategies.Apple,
          Strategies.Google,
          Strategies.GitHub,
          Strategies.Microsoft,
          Strategies.MagicLink,
          Strategies.EmailOtp,
          Strategies.SmsOtp,
          Strategies.Whatsapp
        ] do
      %Variation{id: strategy.__meta__(:id), attributes: %{strategy: strategy}}
    end
  end
end
