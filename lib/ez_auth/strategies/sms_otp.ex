defmodule EzAuth.Strategies.SmsOtp do
  @moduledoc false

  use EzAuth.Strategy,
    id: :sms_otp,
    name: "phone",
    identity: :phone,
    kind: :passwordless
end
