defmodule Storybook.Core.Icon do
  use PhoenixStorybook.Story, :component

  def function, do: &EzAuth.UI.Core.icon/1

  def variations do
    for name <- [:apple, :github, :google, :microsoft, :link, :phone, :envelope] do
      %Variation{id: name, attributes: %{name: name, size: 24}}
    end
  end
end
