defmodule EzAuth.TranslationsTest do
  use ExUnit.Case, async: false

  import EzAuth.Test.Env

  alias EzAuth.Translations

  test "returns interpolated English copy when no gettext backend is configured" do
    with_env(:gettext_backend, nil)

    assert Translations.translate("Continue with %{brand}", brand: "Google") ==
             "Continue with Google"
  end

  test "uses the configured gettext backend" do
    with_env(:gettext_backend, EzAuth.TestGettext)

    assert Translations.translate("Continue") == "Continue"
  end
end
