defmodule EzAuth.Strategies.Apple do
  @moduledoc false

  use EzAuth.Strategy,
    id: :apple,
    name: "Apple",
    identity: :apple,
    kind: :social
end
