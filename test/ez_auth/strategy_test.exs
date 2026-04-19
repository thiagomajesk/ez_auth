defmodule EzAuth.StrategyTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias EzAuth.Strategy

  defmodule Incomplete do
    use EzAuth.Strategy,
      id: :incomplete,
      name: "incomplete",
      identity: :email,
      kind: :passwordless
  end

  defmodule MagicLink do
    use EzAuth.Strategy,
      id: :magic_link,
      name: "link",
      identity: :email,
      kind: :passwordless
  end

  defmodule Partial do
    use EzAuth.Strategy,
      id: :partial,
      name: "partial",
      identity: :email,
      kind: :passwordless

    @impl true
    def request(conn, params), do: {:ok, conn, params}
  end

  test "use defines strategy metadata" do
    assert MagicLink.__meta__() == %{
             id: :magic_link,
             name: "link",
             identity: :email,
             kind: :passwordless
           }

    assert MagicLink.__meta__(:id) == :magic_link
    assert MagicLink.__meta__(:name) == "link"
    assert MagicLink.__meta__(:identity) == :email
    assert MagicLink.__meta__(:kind) == :passwordless
  end

  test "implemented actions override the generated fallback" do
    conn = %{id: 1}
    params = %{"email" => "user@example.com"}

    assert Partial.request(conn, params) == {:ok, conn, params}
  end

  test "missing actions fail closed and log a warning" do
    log =
      capture_log(fn ->
        assert Incomplete.request(%{}, %{}) ==
                 {:error, {:action_not_implemented, :request}}
      end)

    assert log =~ "EzAuth.StrategyTest.Incomplete does not implement :request"
  end

  test "supported_strategies returns the canonical list of strategy modules" do
    assert EzAuth.Strategies.Password in Strategy.supported_strategies()
    assert EzAuth.Strategies.MagicLink in Strategy.supported_strategies()
    assert EzAuth.Strategies.Google in Strategy.supported_strategies()
  end
end
