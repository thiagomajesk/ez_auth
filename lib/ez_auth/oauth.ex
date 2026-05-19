defmodule EzAuth.OAuth do
  @moduledoc false

  @callback authorization_query(state :: String.t()) :: String.t()
  @callback client_id() :: String.t()
  @callback client_secret() :: String.t()
  @callback fetch_identity(code :: String.t()) :: {:ok, String.t()} | {:error, term()}

  defmacro __using__(opts) do
    id = Keyword.fetch!(opts, :id)
    {user_url, opts} = Keyword.pop(opts, :user_url)
    {headers, opts} = Keyword.pop(opts, :headers, [])
    {token_url, opts} = Keyword.pop!(opts, :token_url)
    {authorize_url, opts} = Keyword.pop!(opts, :authorize_url)
    state_key = :"ez_auth_#{id}_state"
    opts = Keyword.merge(opts, identity: id, kind: :social)

    quote do
      use EzAuth.Strategy, unquote(opts)

      import Plug.Conn, only: [get_session: 2, put_session: 3]
      import Phoenix.Controller, only: [redirect: 2]

      alias EzAuth.Accounts
      alias EzAuth.OAuth.Shared

      @behaviour EzAuth.OAuth

      @oauth_headers unquote(headers)
      @oauth_identity unquote(id)
      @oauth_user_url unquote(user_url)
      @oauth_token_url unquote(token_url)
      @oauth_state_key unquote(state_key)
      @oauth_authorize_url unquote(authorize_url)

      @impl true
      def request(conn, _params) do
        state = generate_oauth_state()

        conn =
          conn
          |> put_session(@oauth_state_key, state)
          |> redirect(external: authorization_url(state))

        {:ok, conn, nil}
      end

      @impl true
      def callback(conn, %{"code" => code, "state" => state}) do
        with :ok <- verify_session_state(conn, state),
             {:ok, value} <- fetch_identity(code),
             {:ok, {user, _identity}} <-
               Accounts.find_or_create_social_identity(@oauth_identity, value) do
          {:ok, EzAuth.Auth.sign_in_user(conn, user), user}
        end
      end

      defp authorization_url(state) do
        query = authorization_query(state)

        @oauth_authorize_url
        |> URI.new!()
        |> URI.append_query(query)
        |> URI.to_string()
      end

      defp callback_url do
        EzAuth.Config.endpoint!().url()
        |> URI.merge("/auth/#{EzAuth.Strategy.slug(__MODULE__)}/callback")
        |> URI.to_string()
      end

      defp generate_oauth_state do
        rand = :crypto.strong_rand_bytes(32)
        Base.url_encode64(rand, padding: false)
      end

      defp request_token(code, opts \\ []) do
        opts = Keyword.put(opts, :redirect_uri, callback_url())
        Shared.request_token(code, @oauth_token_url, client_id(), client_secret(), opts)
      end

      defp verify_session_state(conn, state) do
        if get_session(conn, @oauth_state_key) == state,
          do: :ok,
          else: {:error, :invalid_state}
      end
    end
  end
end
