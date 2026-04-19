defmodule EzAuth.Test.QueryHelpers do
  @moduledoc false

  import Ecto.Query

  alias EzAuth.Accounts.Identity
  alias EzAuth.Accounts.Verification

  def fetch_identity!(repo, type, value) do
    repo.one!(from(i in Identity, where: i.type == ^type, where: i.value == ^value))
  end

  def fetch_verification!(repo, type, value) do
    repo.one!(from(v in Verification, where: v.type == ^type, where: v.value == ^value))
  end
end
