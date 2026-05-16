defmodule EzAuth.Accounts.SignUpE2ETest do
  use EzAuth.Test.DataCase, async: true

  import EzAuth.Test.Factory
  import EzAuth.TestConfig
  import Phoenix.ConnTest

  alias EzAuth.Accounts.User
  alias EzAuth.Dispatcher
  alias EzAuth.Test.Handler
  alias EzAuth.Test.QueryHelpers
  alias EzAuth.TestRepo

  describe "sign_up/2" do
    test "creates an email user with persisted identity and verification" do
      stub_config(strategies: [EzAuth.Strategies.Password])

      params =
        :email_sign_up_attrs
        |> build()
        |> Map.put("email", "new@example.com")

      assert %Plug.Conn{} = Dispatcher.sign_up(build_dispatcher_conn(), %{"user" => params})

      assert %{user_id: user_id, verified_at: nil} =
               QueryHelpers.fetch_identity!(TestRepo, :email, "new@example.com")

      assert %User{id: ^user_id} = TestRepo.get!(User, user_id)

      assert %{type: :email, value: "new@example.com"} =
               QueryHelpers.fetch_verification!(TestRepo, :email, "new@example.com")
    end

    test "rejects invalid attrs without persisting anything" do
      stub_config(strategies: [EzAuth.Strategies.Password])

      assert %Plug.Conn{} =
               Dispatcher.sign_up(build_dispatcher_conn(), %{
                 "user" => %{"email" => "not-an-email"}
               })

      assert TestRepo.aggregate(User, :count) == 0
    end
  end

  defp build_dispatcher_conn do
    Plug.Conn.put_private(build_conn(), :ez_auth, %{handler: Handler})
  end
end
