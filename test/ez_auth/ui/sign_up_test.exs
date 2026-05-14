defmodule EzAuth.UI.SignUpTest do
  use ExUnit.Case, async: true
  use Mimic

  import EzAuth.TestConfig
  import Phoenix.LiveViewTest

  alias EzAuth.Strategies
  alias EzAuth.UI.SignUp

  describe "render/1" do
    test "renders email + password form when Password is enabled" do
      stub_config(strategies: [Strategies.Password])

      html = render_component(SignUp, id: "sign-up")

      assert html =~ ~s(autocomplete="email")
      assert html =~ ~s(autocomplete="new-password")
    end

    test "renders previously typed email + password values when the form carries changes" do
      stub_config(strategies: [Strategies.Password])

      changeset =
        Ecto.Changeset.cast(
          %EzAuth.Accounts.User{},
          %{"email" => "user@example.com", "password" => "secret123"},
          [:email, :password]
        )

      form = Phoenix.Component.to_form(changeset)

      html = render_component(SignUp, id: "sign-up", form: form)

      assert html =~ ~s(value="user@example.com")
      assert html =~ ~s(value="secret123")
    end

    test "preserves field values across change events" do
      stub_config(strategies: [Strategies.Password])
      stub(EzAuth.Accounts, :email_taken?, fn _ -> false end)

      socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, myself: nil}}

      params = %{
        "user" => %{
          "email" => "user@example.com",
          "password" => "secret123"
        },
        "_target" => ["user", "email"]
      }

      assert {:noreply, %{assigns: %{form: form}}} =
               SignUp.handle_event("change", params, socket)

      assert form[:email].value == "user@example.com"
      assert form[:password].value == "secret123"
    end

    test "renders schema-namespaced field names so the server can unwrap params" do
      stub_config(strategies: [Strategies.Password])

      html = render_component(SignUp, id: "sign-up")

      assert html =~ ~s(name="user[email]")
      assert html =~ ~s(name="user[password]")
    end

    test "omits the form section when Password is not enabled" do
      stub_config(strategies: [Strategies.MagicLink])

      html = render_component(SignUp, id: "sign-up")

      refute html =~ ~s(autocomplete="email")
      refute html =~ ~s(autocomplete="new-password")
    end

    test "renders sign-in option buttons for non-credential strategies in config order" do
      stub_config(strategies: [Strategies.Password, Strategies.MagicLink, Strategies.SmsOtp])

      html = render_component(SignUp, id: "sign-up")

      assert html =~ "Continue with link"
      assert html =~ "Continue with phone"
    end

    test "shows social brand buttons when social strategies are configured" do
      stub_config(strategies: [Strategies.Password, Strategies.Google])

      html = render_component(SignUp, id: "sign-up")

      assert html =~ "Continue with Google"
    end

    test "truncates the sign-in options list to 3 entries by default" do
      stub_config(
        strategies: [
          Strategies.Password,
          Strategies.MagicLink,
          Strategies.SmsOtp,
          Strategies.Google,
          Strategies.Apple
        ]
      )

      html = render_component(SignUp, id: "sign-up")

      assert html =~ "More sign in options"
    end

    test "no More toggle when 3 or fewer sign-in options" do
      stub_config(strategies: [Strategies.Password, Strategies.MagicLink])

      html = render_component(SignUp, id: "sign-up")

      refute html =~ "More sign in options"
    end

    test "does not render name or username inputs" do
      stub_config(strategies: [Strategies.Password])

      html = render_component(SignUp, id: "sign-up")

      refute html =~ ~s(autocomplete="name")
      refute html =~ ~s(autocomplete="username")
    end
  end
end
