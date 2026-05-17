defmodule Mix.Tasks.EzAuth.Install do
  @moduledoc """
  Copies EzAuth migrations into the host application.

  Pass `--replace` to refresh existing EzAuth migration files in place.
  """

  use Mix.Task

  @shortdoc "Copies EzAuth migrations into the host application"

  @impl true
  def run(args) do
    Mix.Task.run("app.config")

    {opts, _args} = OptionParser.parse!(args, strict: [replace: :boolean])

    File.mkdir_p!(target_dir())

    opts[:replace]
    |> copy_migrations()
    |> print_summary()
  end

  defp compile_template({source, index}, started_at) do
    name = migration_name(source)
    target = Path.join(target_dir(), "#{timestamp(started_at, index)}_#{name}")

    {target, EEx.eval_file(source, repo: EzAuth.Config.repo!())}
  end

  defp copy_migration({target, content}, replace?) do
    case existing_migration(target) do
      nil ->
        write_migration(target, content)

      path when replace? ->
        write_migration(path, content)

      path ->
        {:skip, path}
    end
  end

  defp copy_migrations(replace?) do
    started_at = DateTime.utc_now()

    source_migrations()
    |> Enum.with_index()
    |> Enum.map(&compile_template(&1, started_at))
    |> Enum.map(&copy_migration(&1, replace?))
  end

  defp existing_migration(target) do
    name = Regex.escape(migration_name(target))
    pattern = Regex.compile!("^\\d{14}_#{name}$")

    target_dir()
    |> Path.join("*.exs")
    |> Path.wildcard()
    |> Enum.find(&(Path.basename(&1) =~ pattern))
  end

  defp migration_name(path) do
    path
    |> Path.basename()
    |> String.replace(~r/^\d+_/, "")
    |> String.replace_suffix(".eex", "")
  end

  defp print_summary(results) do
    Enum.each(results, fn
      {:copy, path} -> Mix.shell().info("* copied #{Path.relative_to_cwd(path)}")
      {:skip, path} -> Mix.shell().info("* skipped #{Path.relative_to_cwd(path)}")
    end)
  end

  defp source_dir, do: Path.join(:code.priv_dir(:ez_auth), "templates/ez_auth.install")

  defp source_migrations do
    source_dir()
    |> Path.join("*.exs.eex")
    |> Path.wildcard()
    |> Enum.sort()
  end

  defp target_dir,
    do: Path.join(Mix.EctoSQL.source_repo_priv(EzAuth.Config.repo!()), "migrations")

  defp timestamp(datetime, offset) do
    datetime
    |> DateTime.add(offset, :second)
    |> Calendar.strftime("%Y%m%d%H%M%S")
  end

  defp write_migration(target, content) do
    File.write!(target, content)
    {:copy, target}
  end
end
