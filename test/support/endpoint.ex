defmodule EzAuth.Test.Endpoint do
  use Phoenix.Endpoint, otp_app: :ez_auth

  plug(Plug.Session,
    store: :cookie,
    key: "_auth_test_key",
    signing_salt: "test_salt"
  )
end
