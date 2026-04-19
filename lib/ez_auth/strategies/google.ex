defmodule EzAuth.Strategies.Google do
  @moduledoc false

  use EzAuth.Strategy,
    id: :google,
    name: "Google",
    identity: :google,
    kind: :social
end
