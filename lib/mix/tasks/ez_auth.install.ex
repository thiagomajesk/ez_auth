defmodule Mix.Tasks.EzAuth.Install do
  @moduledoc """
  Copies EzAuth migrations into the host application.
  """

  use Mix.Task

  @shortdoc "Copies EzAuth migrations into the host application"

  @impl true
  def run(_args) do
    Mix.Task.run("app.config")

    source_dir = Path.join(:code.priv_dir(:ez_auth), "repo/migrations")
    target_dir = Path.join(File.cwd!(), "priv/repo/migrations")

    File.mkdir_p!(target_dir)

    source_dir
    |> migrations()
    |> copy_migrations(target_dir)
    |> print_summary()
  end

  defp migrations(source_dir) do
    source_dir
    |> Path.join("*.exs")
    |> Path.wildcard()
    |> Enum.sort()
  end

  defp copy_migrations(migrations, target_dir) do
    started_at = DateTime.utc_now()

    migrations
    |> Enum.with_index()
    |> Enum.map(&copy_migration(&1, target_dir, started_at))
  end

  defp copy_migration({source, index}, target_dir, started_at) do
    target = target_migration_path(source, target_dir, started_at, index)

    case File.cp(source, target) do
      :ok ->
        target

      {:error, reason} ->
        Mix.raise("could not copy #{source}: #{:file.format_error(reason)}")
    end
  end

  defp migration_name(path) do
    path
    |> Path.basename()
    |> String.replace(~r/^\d+_/, "")
  end

  defp print_summary(results) do
    Enum.each(results, &Mix.shell().info("* copied #{Path.relative_to_cwd(&1)}"))
  end

  defp target_migration_path(source, target_dir, started_at, index) do
    name = migration_name(source)
    Path.join(target_dir, "#{timestamp(started_at, index)}_#{name}")
  end

  defp timestamp(datetime, offset) do
    datetime
    |> DateTime.add(offset, :second)
    |> Calendar.strftime("%Y%m%d%H%M%S")
  end
end
