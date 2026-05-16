defmodule EzAuth.SenderTest do
  use EzAuth.Test.MoxCase, async: true

  import ExUnit.CaptureLog

  alias EzAuth.Sender
  alias EzAuth.Test.Sender, as: TestSender

  describe "maybe_invoke/3" do
    test "returns :ok quietly when no sender is configured" do
      assert :ok = Sender.maybe_invoke(nil, :email, %{user: %{id: 1}})
    end

    test "logs skipped delivery when the configured sender does not implement deliver/2" do
      sender = Module.concat([__MODULE__, NoopSender])

      Logger.configure(level: :info)

      on_exit(fn ->
        Logger.configure(level: :warning)
      end)

      assert capture_log([level: :info], fn ->
               assert :ok = Sender.maybe_invoke(sender, :email, %{user: %{id: 1}})
             end) =~ "EzAuth sender #{inspect(sender)} does not implement deliver/2"
    end

    test "delegates delivery to the configured sender" do
      expect(TestSender, :deliver, fn :email, %{token: "token"} -> :ok end)

      assert :ok = Sender.maybe_invoke(TestSender, :email, %{token: "token"})
    end
  end
end
