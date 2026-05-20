defmodule EzAuth.Strategies.Whatsapp do
  @moduledoc false

  use EzAuth.Strategy,
    provider: "whatsapp",
    name: "WhatsApp",
    identity: :phone,
    kind: :passwordless
end
