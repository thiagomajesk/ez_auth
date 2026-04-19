defmodule EzAuth.Strategies.Whatsapp do
  @moduledoc false

  use EzAuth.Strategy,
    id: :whatsapp,
    name: "WhatsApp",
    identity: :phone,
    kind: :passwordless
end
