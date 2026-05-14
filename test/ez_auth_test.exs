defmodule EzAuthTest do
  use ExUnit.Case, async: true

  describe "auth_routes/1 scope validation" do
    test "compiles when invoked at the router top level" do
      assert [_ | _] =
               compile_router("""
               defmodule #{router_name()} do
                 use Phoenix.Router
                 use EzAuth

                 auth_routes(handler: Some.Handler)
               end
               """)
    end

    test "raises at compile time when wrapped in a scope that sets :path" do
      assert_raise CompileError, ~r/auth_routes\/1 must be invoked at the router's top level/, fn ->
        compile_router("""
        defmodule #{router_name()} do
          use Phoenix.Router
          use EzAuth

          scope "/admin" do
            auth_routes(handler: Some.Handler)
          end
        end
        """)
      end
    end

    test "raises at compile time when wrapped in a scope that sets :alias" do
      assert_raise CompileError, fn ->
        compile_router("""
        defmodule #{router_name()} do
          use Phoenix.Router
          use EzAuth

          scope "/", SomeAlias do
            auth_routes(handler: Some.Handler)
          end
        end
        """)
      end
    end
  end

  defp compile_router(source), do: Code.compile_string(source)

  defp router_name,
    do: "EzAuthTest.Fake#{System.unique_integer([:positive])}"
end
