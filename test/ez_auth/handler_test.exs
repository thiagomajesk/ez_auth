defmodule EzAuth.HandlerTest do
  use EzAuth.Test.MoxCase, async: true

  alias EzAuth.Handler
  alias EzAuth.Test.Handler, as: TestHandler

  defmodule NoopHandler do
  end

  describe "maybe_invoke/4" do
    test "returns the connection unchanged when no handler is configured" do
      conn = %{id: 1}

      assert conn ==
               Handler.maybe_invoke(conn, nil, :handle_success, [
                 {:password, :request},
                 %{id: 1}
               ])
    end

    test "calls the configured callback when it is exported" do
      conn = %{id: 1}
      user = %{id: 10}

      expect(TestHandler, :handle_success, fn ^conn, {:password, :request}, ^user ->
        Map.put(conn, :handled, true)
      end)

      assert %{handled: true} =
               Handler.maybe_invoke(conn, TestHandler, :handle_success, [
                 {:password, :request},
                 user
               ])
    end

    test "returns the connection unchanged when the callback is not exported" do
      conn = %{id: 1}

      assert conn ==
               Handler.maybe_invoke(conn, NoopHandler, :handle_success, [
                 {:password, :request},
                 %{id: 1}
               ])
    end
  end
end
