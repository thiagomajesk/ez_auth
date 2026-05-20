defmodule EzAuth.Test.Strategy do
  @moduledoc false

  use EzAuth.Strategy,
    provider: "test",
    name: "test",
    identity: :email,
    kind: :credential
end
