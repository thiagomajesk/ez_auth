defmodule EzAuth.Test.SocketHelpers do
  @moduledoc false

  def build_socket do
    %Phoenix.LiveView.Socket{
      private: %{connect_params: %{}, live_temp: %{}},
      assigns: %{__changed__: %{}, flash: %{}}
    }
  end
end
