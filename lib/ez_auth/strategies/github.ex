defmodule EzAuth.Strategies.GitHub do
  @moduledoc false

  use EzAuth.Strategy,
    id: :github,
    name: "GitHub",
    identity: :github,
    kind: :social
end
