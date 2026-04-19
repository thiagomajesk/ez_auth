defmodule EzAuth.Test.ConnHelpers do
  @moduledoc false

  import Phoenix.ConnTest, only: [build_conn: 0]
  import Plug.Test, only: [init_test_session: 2]

  def build_session_conn(session \\ %{}) do
    init_test_session(build_conn(), session)
  end
end
