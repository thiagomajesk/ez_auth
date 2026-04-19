defmodule EzAuth.Test.Strategy do
  @moduledoc false

  use EzAuth.Strategy,
    id: :test,
    name: "test",
    identity: :email,
    kind: :credential
end
