defmodule EzAuth.Strategy do
  @moduledoc """
  Behaviour implemented by authentication strategies.
  """

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

  @http_methods [:connect, :delete, :get, :head, :options, :patch, :post, :put, :trace]

  def supported_strategies, do: @supported_strategies

  @type result :: {:ok, Plug.Conn.t(), user :: struct() | nil} | {:error, reason :: term()}

  @type meta :: %{
          id: atom(),
          name: String.t(),
          identity: atom(),
          kind: :credential | :passwordless | :social,
          callback_methods: [atom()]
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
    callback_methods = Keyword.get(opts, :callback_methods, [:get])

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

    if not is_list(callback_methods) or Enum.any?(callback_methods, &(&1 not in @http_methods)),
      do:
        raise(
          ArgumentError,
          "strategy :callback_methods must be a list of atoms representing valid HTTP methods"
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
          kind: unquote(kind),
          callback_methods: unquote(callback_methods)
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
    id = strategy.__meta__(:id)
    String.replace(to_string(id), "_", "-")
  end
end
