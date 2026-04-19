defmodule EzAuth.Test.Env do
  @moduledoc false

  def with_env(key, value) when is_atom(key), do: with_env([{key, value}])

  def with_env(keys) when is_list(keys) and is_atom(hd(keys)),
    do: with_env(Enum.map(keys, &{&1, nil}))

  def with_env(values) when is_list(values) do
    originals =
      for {key, _value} <- values, into: %{} do
        {key, Application.fetch_env(:ez_auth, key)}
      end

    Enum.each(values, fn
      {key, nil} -> Application.delete_env(:ez_auth, key)
      {key, value} -> Application.put_env(:ez_auth, key, value)
    end)

    ExUnit.Callbacks.on_exit(fn ->
      Enum.each(originals, fn
        {key, :error} -> Application.delete_env(:ez_auth, key)
        {key, {:ok, value}} -> Application.put_env(:ez_auth, key, value)
      end)
    end)
  end
end
