defmodule Commands do
  @moduledoc """
  Functions for CLI commands
  """
  alias Objects.Commit
  alias Objects.Tree
  alias Objects.Blob
  alias Utils.Emojis
  alias Utils.Terminal

  @spec init(String.t()) :: any()
  def init(path) do
    abs_path = Path.expand(path)
    ralph_path = Path.join([abs_path, ".git"])

    ["objects", "refs"]
    |> Enum.each(fn folder ->
      try do
        File.mkdir_p!(Path.join([ralph_path, folder]))
      rescue
        err ->
          Terminal.puts(
            IO.ANSI.red(),
            "Sorry there's an error while creating files due to #{inspect(err)} #{Emojis.emojis().snowman}",
            :stderr
          )

          System.halt(1)
      end
    end)

    Terminal.puts(
      IO.ANSI.green(),
      "Initialized empty ralph repo at #{ralph_path} #{Emojis.emojis().clinking_glasses}"
    )

    System.halt(0)
  end

  @doc """
  Commits the uncommited files

  get cur directory
  list the files init.
  """
  @spec commit(String.t()) :: any()
  def commit(msg) do
    msg = msg |> String.trim()
    workspace_path = Path.expand(".")
    ralph_path = Path.join([workspace_path, ".git"])
    db_path = Path.join([ralph_path, "objects"])

    blob_objs =
      Workspace.list_files!(workspace_path, workspace_path)
      |> Enum.map(fn file ->
        data = Workspace.read_file(Path.join([workspace_path, file]))

        stat = Workspace.stat_file(Path.join([workspace_path, file]))

        # converting stat to a base octal integer
        obj =
          Blob.new(data, Integer.to_string(stat.mode, 8) |> String.to_integer())
          |> Database.store(db_path)

        {file, obj}
      end)
      |> IO.inspect()

    tree =
      Tree.new(blob_objs)
      |> Database.store(db_path)

    author_name = System.get_env("RALPH_AUTHOR_NAME", "john doe")
    author_email = System.get_env("RALPH_AUTHOR_EMAIL", "jd@unknown.com")
    parent = Refs.read_head(ralph_path)

    author =
      "#{author_name} <#{author_email}> #{DateTime.utc_now() |> Calendar.strftime("%s %z")}"

    commit =
      Commit.new(parent, Object.oid(tree), author, msg)
      |> Database.store(db_path)

    :ok = Refs.update_head(commit, ralph_path)

    if is_nil(parent) do
      IO.puts("[(root-commit) #{Object.oid(commit)}] #{msg}")
    else
      IO.puts("[#{Object.oid(commit)}] #{msg}")
    end

    System.halt(0)
  end
end
