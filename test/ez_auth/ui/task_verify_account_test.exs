defmodule EzAuth.UI.TaskVerifyAccountTest do
  use ExUnit.Case, async: true
  use Mimic

  import EzAuth.TestConfig
  import Phoenix.LiveViewTest

  alias EzAuth.UI.TaskVerifyAccount
  alias Phoenix.LiveView.JS

  setup do
    stub_config()
    :ok
  end

  describe "render/1" do
    test "renders the title, subtitle, and a code input row" do
      html = render_component(TaskVerifyAccount, id: "verify")

      assert html =~ "Verify your account"
      assert html =~ "Enter the verification code sent to your account."
      assert html =~ ~s(autocomplete="one-time-code")
    end

    test "renders the identity below the header when given" do
      html =
        render_component(TaskVerifyAccount, id: "verify", identity: "user@example.com")

      assert html =~ ~s(data-part="verify-identity")
      assert html =~ "user@example.com"
    end

    test "omits the identity span when not given" do
      html = render_component(TaskVerifyAccount, id: "verify")

      refute html =~ ~s(data-part="verify-identity")
    end

    test "renders the configured number of input boxes" do
      html = render_component(TaskVerifyAccount, id: "verify", length: 4)

      assert length(Regex.scan(~r/data-part="code-input-box"/, html)) == 4
    end

    test "shows the Back button only when on_back is given" do
      without = render_component(TaskVerifyAccount, id: "verify")
      with_back = render_component(TaskVerifyAccount, id: "verify", on_back: %JS{})

      refute without =~ ~s(data-part="back")
      assert with_back =~ ~s(data-part="back")
    end
  end
end
