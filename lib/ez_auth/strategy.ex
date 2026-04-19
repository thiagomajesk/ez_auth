defmodule EzAuth.Strategy do
  @moduledoc """
  Behaviour implemented by authentication strategies.
  """

  alias EzAuth.Config

  @supported_strategies [
    EzAuth.Strategies.Password,
    EzAuth.Strategies.MagicLink,
    EzAuth.Strategies.EmailOtp,
    EzAuth.Strategies.SmsOtp,
    EzAuth.Strategies.Whatsapp,
    EzAuth.Strategies.Apple,
    EzAuth.Strategies.Google,
    EzAuth.Strategies.GitHub,
    EzAuth.Strategies.Microsoft
  ]

  def supported_strategies, do: @supported_strategies

  @type result :: {:ok, Plug.Conn.t(), user :: struct()} | {:error, reason :: term()}

  @type meta :: %{
          id: atom(),
          name: String.t(),
          identity: atom(),
          kind: :credential | :passwordless | :social
        }

  @callback __meta__() :: meta
  @callback __meta__(key :: atom()) :: term()
  @callback request(conn :: Plug.Conn.t(), params :: map()) :: result
  @callback callback(conn :: Plug.Conn.t(), params :: map()) :: result

  defmacro __using__(opts) do
    id = Keyword.fetch!(opts, :id)
    name = Keyword.fetch!(opts, :name)
    identity = Keyword.fetch!(opts, :identity)
    kind = Keyword.fetch!(opts, :kind)

    if not is_atom(id),
      do: raise(ArgumentError, "strategy :id must be an atom")

    if not is_binary(name),
      do: raise(ArgumentError, "strategy :name must be a string")

    if not is_atom(identity),
      do: raise(ArgumentError, "strategy :identity must be an atom")

    if kind not in [:credential, :passwordless, :social],
      do:
        raise(
          ArgumentError,
          "strategy :kind must be one of :credential, :passwordless, :social"
        )

    quote do
      require Logger

      @behaviour EzAuth.Strategy

      @impl true
      def __meta__ do
        %{
          id: unquote(id),
          name: unquote(name),
          identity: unquote(identity),
          kind: unquote(kind)
        }
      end

      @impl true
      def __meta__(key), do: Map.fetch!(__meta__(), key)

      @impl true
      def request(_conn, _params) do
        Logger.warning("#{inspect(__MODULE__)} does not implement :request")
        {:error, {:action_not_implemented, :request}}
      end

      @impl true
      def callback(_conn, _params) do
        Logger.warning("#{inspect(__MODULE__)} does not implement :callback")
        {:error, {:action_not_implemented, :callback}}
      end

      defoverridable request: 2, callback: 2
    end
  end

  def slug(strategy) do
    strategy.__meta__(:id)
    |> to_string()
    |> String.replace("_", "-")
  end

  def helper(strategy, action),
    do: :"ez_auth_#{strategy.__meta__(:id)}_#{action}"

  def path(strategy, action) do
    router = Module.concat(Config.router!(), Helpers)
    helper_name = :"#{helper(strategy, action)}_path"
    apply(router, helper_name, [Config.endpoint!(), action])
  end
end
