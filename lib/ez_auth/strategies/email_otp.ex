defmodule EzAuth.Strategies.EmailOtp do
  @moduledoc false

  use EzAuth.Strategy,
    id: :email_otp,
    name: "email",
    identity: :email,
    kind: :passwordless
end
