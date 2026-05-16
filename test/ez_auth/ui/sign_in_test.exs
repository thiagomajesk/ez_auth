defmodule EzAuth.UI.SignInTest do
  use ExUnit.Case, async: true
  use Mimic

  import EzAuth.TestConfig
  import Phoenix.LiveViewTest

  alias EzAuth.Strategies
  alias EzAuth.UI.SignIn

  describe "render/1" do
    test "renders the poly identity input when at least one identity strategy is enabled" do
      stub_config(strategies: [Strategies.Password])

      html = render_component(SignIn, id: "sign-in")

      assert html =~ ~s(name="_identity")
    end

    test "renders social buttons below the form when social strategies are enabled" do
      stub_config(strategies: [Strategies.Password, Strategies.Google])

      html = render_component(SignIn, id: "sign-in")

      assert html =~ "Continue with Google"
    end

    test "poly input is restricted to email when only email-anchored strategies are enabled" do
      stub_config(strategies: [Strategies.Password, Strategies.MagicLink])

      html = render_component(SignIn, id: "sign-in")

      assert html =~ ~s(name="_identity")
      refute html =~ ~s(type="tel")
    end

    test "links to the configured sign-up page" do
      stub_config(strategies: [Strategies.Password], sign_up_path: "/join")

      html = render_component(SignIn, id: "sign-in")

      assert html =~ ~s(href="/join")
      refute html =~ ~s(href="/auth/sign-up")
    end
  end
end
