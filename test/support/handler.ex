defmodule EzAuth.Test.Handler do
  @moduledoc false
  @behaviour EzAuth.Handler

  @impl true
  def handle_success(conn, _action, _user), do: conn

  @impl true
  def handle_failure(conn, _action, _reason), do: conn
end
