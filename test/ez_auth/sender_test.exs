defmodule EzAuth.SenderTest do
  use EzAuth.Test.MoxCase, async: true

  alias EzAuth.Sender
  alias EzAuth.Test.Sender, as: TestSender

  describe "maybe_invoke/3" do
    test "returns :ok when no sender is configured" do
      assert :ok = Sender.maybe_invoke(nil, :email, %{user: %{id: 1}})
    end

    test "delegates delivery to the configured sender" do
      expect(TestSender, :deliver, fn :email, %{token: "token"} -> :ok end)

      assert :ok = Sender.maybe_invoke(TestSender, :email, %{token: "token"})
    end
  end
end
