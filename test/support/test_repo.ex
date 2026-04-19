defmodule EzAuth.TestRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :ez_auth,
    adapter: Ecto.Adapters.Postgres
end
