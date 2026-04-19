defmodule EzAuth.Strategies.Microsoft do
  @moduledoc false

  use EzAuth.Strategy,
    id: :microsoft,
    name: "Microsoft",
    identity: :microsoft,
    kind: :social
end
