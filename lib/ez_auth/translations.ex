defmodule EzAuth.Translations do
  @moduledoc """
  Translation helpers for EzAuth-owned user-facing copy.
  """

  import Gettext.Interpolation.Default, only: [runtime_interpolate: 2]

  def translate(msg, bindings \\ [], count \\ 1) do
    case Application.get_env(:ez_auth, :gettext_backend) do
      nil -> interpolate(msg, bindings)
      backend -> Gettext.dngettext(backend, "ez_auth", msg, msg, count, bindings)
    end
  end

  defp interpolate(msg, bindings) do
    case runtime_interpolate(msg, Map.new(bindings)) do
      {:ok, msg} -> msg
      {:missing_bindings, msg, _missing} -> msg
    end
  end
end
