defmodule EzAuth.Test.Sender do
  @moduledoc false
  @behaviour EzAuth.Sender

  @impl true
  def deliver(_event, _scope), do: :ok
end
