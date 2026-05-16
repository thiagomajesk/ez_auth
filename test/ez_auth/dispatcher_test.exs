defmodule EzAuth.DispatcherTest do
  use EzAuth.Test.MoxCase, async: true

  import Phoenix.ConnTest
  import Plug.Conn

  alias EzAuth.Accounts
  alias EzAuth.Auth
  alias EzAuth.Dispatcher
  alias EzAuth.Scopes.UserScope
  alias EzAuth.Test.Handler
  alias EzAuth.Test.Strategy

  describe "request/2" do
    test "delegates successful strategy calls to the handler" do
      conn = put_ez_auth(build_conn(), strategy: Strategy, handler: Handler)
      user = %{id: 1}

      expect(Strategy, :request, fn ^conn, %{"email" => "user@example.com"} ->
        {:ok, conn, user}
      end)

      expect(Handler, :handle_success, fn ^conn, {:test, :request}, ^user ->
        assign(conn, :handled, :success)
      end)

      assert %{assigns: %{handled: :success}} =
               Dispatcher.request(conn, %{"user" => %{"email" => "user@example.com"}})
    end

    test "delegates strategy failures to the handler" do
      conn = put_ez_auth(build_conn(), strategy: Strategy, handler: Handler)

      expect(Strategy, :request, fn ^conn, _params ->
        {:error, :invalid_credentials}
      end)

      expect(Handler, :handle_failure, fn ^conn, {:test, :request}, :invalid_credentials ->
        assign(conn, :handled, :failure)
      end)

      assert %{assigns: %{handled: :failure}} = Dispatcher.request(conn, %{"user" => %{}})
    end
  end

  describe "callback/2" do
    test "delegates successful strategy calls to the handler" do
      conn = put_ez_auth(build_conn(), strategy: Strategy, handler: Handler)
      user = %{id: 1}

      expect(Strategy, :callback, fn ^conn, %{"token" => "abc"} ->
        {:ok, conn, user}
      end)

      expect(Handler, :handle_success, fn ^conn, {:test, :callback}, ^user ->
        assign(conn, :handled, :success)
      end)

      assert %{assigns: %{handled: :success}} =
               Dispatcher.callback(conn, %{"user" => %{"token" => "abc"}})
    end
  end

  describe "sign_out/2" do
    test "signs the user out and reports success to the handler" do
      user = %{id: 1}

      conn =
        build_conn()
        |> assign(:current_scope, UserScope.new(user))
        |> put_ez_auth(handler: Handler)

      expect(Auth, :sign_out_user, fn ^conn, ^user ->
        assign(conn, :signed_out, true)
      end)

      expect(Handler, :handle_success, fn %{assigns: %{signed_out: true}} = conn,
                                          {:default, :sign_out},
                                          ^user ->
        assign(conn, :handled, true)
      end)

      assert %{assigns: %{handled: true}} = Dispatcher.sign_out(conn, %{})
    end
  end

  describe "sign_up/2" do
    test "reports successful sign ups to the handler" do
      conn = put_ez_auth(build_conn(), handler: Handler)
      user = %{id: 1}
      identity = %EzAuth.Accounts.Identity{type: :email, value: "user@example.com", user: user}

      expect(Accounts, :create_user_with_password, fn %{"email" => "user@example.com"} ->
        {:ok, {user, identity}}
      end)

      expect(Accounts, :request_email_verification, fn ^identity -> :ok end)

      expect(Handler, :handle_success, fn ^conn, {:default, :sign_up}, ^user ->
        assign(conn, :handled, :success)
      end)

      assert %{assigns: %{handled: :success}} =
               Dispatcher.sign_up(conn, %{"user" => %{"email" => "user@example.com"}})
    end

    test "reports sign up failures to the handler" do
      conn = put_ez_auth(build_conn(), handler: Handler)
      changeset = %{errors: [email: {"has already been taken", []}]}

      expect(Accounts, :create_user_with_password, fn %{"email" => "user@example.com"} ->
        {:error, changeset}
      end)

      expect(Handler, :handle_failure, fn ^conn, {:default, :sign_up}, ^changeset ->
        assign(conn, :handled, :failure)
      end)

      assert %{assigns: %{handled: :failure}} =
               Dispatcher.sign_up(conn, %{"user" => %{"email" => "user@example.com"}})
    end
  end

  defp put_ez_auth(conn, ctx), do: put_private(conn, :ez_auth, Map.new(ctx))
end
