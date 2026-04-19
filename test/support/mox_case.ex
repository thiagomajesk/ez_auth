defmodule EzAuth.Test.MoxCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      use Mimic
    end
  end
end
