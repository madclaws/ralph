defmodule Commands do
  @moduledoc """
  Functions for CLI commands
  """
  alias Objects.Index
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
        Blob.new(data, file, Integer.to_string(stat.mode, 8) |> String.to_integer())
        |> Database.store(db_path)
      end)

    # A bootiful closure ..
    # This makes db_path accessible even inside the Tree.traverse fn which is in
    # Tree module without even explicitly passing in lamda.
    db_fn = fn object -> Database.store(object, db_path) end

    tree =
      Tree.build(blob_objs)
      |> Tree.traverse(db_fn)

    tree = Database.store(tree, db_path)
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

  @spec add(list(Path.t())) :: any()
  def add(file_paths) do
    workspace_path = Path.expand(".")
    ralph_path = Path.join([workspace_path, ".git"])
    db_path = Path.join([ralph_path, "objects"])
    index = Index.new(Path.join([ralph_path, "index"]))

    Enum.reduce(file_paths, index, fn file_path, index ->
      abs_path = Path.expand(file_path)

      Workspace.list_files!(abs_path, workspace_path)
      |> Enum.reduce(index, fn file_path, index ->
        data = Workspace.read_file(Path.join([workspace_path, file_path]))

        stat = Workspace.stat_file(Path.join([workspace_path, file_path]))

        blob =
          Blob.new(data, file_path)
          |> Database.store(db_path)

        Index.add(index, file_path, Object.oid(blob), stat)
      end)
    end)
    |> Index.write_updates()

    System.halt(0)
  end
end
