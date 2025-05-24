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

  @doc """
  Inititialized a ralph repository

  Can use `ralph init <path>` from CLI

  Creates a .git folder and child folders like Objects and refs
  """
  @spec init(String.t()) :: any()
  def init(path \\ ".") do
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
  end

  @doc """
  Commits the uncommited files
  """
  @spec commit(String.t()) :: any()
  def commit(msg) do
    msg = msg |> String.trim()
    workspace_path = Path.expand(".")
    ralph_path = Path.join([workspace_path, ".git"])
    db_path = Path.join([ralph_path, "objects"])

    index =
      Index.new(Path.join([ralph_path, "index"]))
      |> Index.load()

    # Dummy blobs for tree building, maybe w'll change later
    blob_objs =
      Enum.map(index.entries, fn {k, v} ->
        # Data is empty here since we already wrote the Blob to disk in `ralph add`
        # But how do u create correct hashes then - For creating hash of trees we only
        # need hash of Blob, which we have from Index.
        Blob.new("", k, Integer.to_string(v[:mode], 8) |> String.to_integer(), v[:oid])
      end)

    # A bootiful closure ..
    # This makes db_path accessible even inside the Tree.traverse fn which is in
    # Tree module without even explicitly passing in Tree.traverse() at ln:no 75.
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
  end

  @doc """
  Creates the compressed files in the disk and adds into the Index file

  Can use `ralph add <path>` from CLI   
  """
  @spec add(list(Path.t())) :: any()
  def add(file_paths, wrk_path \\ ".") do
    workspace_path = Path.expand(wrk_path)
    ralph_path = Path.join([workspace_path, ".git"])
    # db_path is basically .git/objects where all the compressed blobs are stored
    # by their hashes
    db_path = Path.join([ralph_path, "objects"])

    index =
      Index.new(Path.join([ralph_path, "index"]))
      |> Index.load()

    paths =
      try do
        Enum.flat_map(file_paths, fn file_path ->
          abs_path = Path.expand(file_path)
          Workspace.list_files!(abs_path, workspace_path)
        end)
      rescue
        err ->
          Terminal.puts(
            IO.ANSI.red(),
            "Fatal #{inspect(err)} #{Emojis.emojis().snowman}",
            :stderr
          )

          System.halt(1)
      end

    index =
      try do
        paths
        |> Enum.reduce(index, fn file_path, index ->
          data = Workspace.read_file(Path.join([workspace_path, file_path]))

          stat = Workspace.stat_file(Path.join([workspace_path, file_path]))

          blob =
            Blob.new(data, file_path)
            |> Database.store(db_path)

          Index.add(index, file_path, Object.oid(blob), stat)
        end)
      rescue
        err ->
          Terminal.puts(
            IO.ANSI.red(),
            "error: #{inspect(err)} #{Emojis.emojis().snowman}",
            :stderr
          )

          Terminal.puts(
            IO.ANSI.red(),
            "fatal: adding files failed",
            :stderr
          )

          System.halt(1)
      end

    Index.write_updates(index)
  end

  @spec load() :: any()
  def load() do
    workspace_path = Path.expand(".")
    index = Index.new(Path.join([workspace_path, ".git/index"]))
    Index.load(index)
  end

  @spec status() :: any()
  def status(path \\ ".") do
    workspace_path = Path.expand(path)
    ralph_path = Path.join([workspace_path, ".git"])

    index =
      Index.new(Path.join([ralph_path, "index"]))
      |> Index.load()

    untracked = scan_workspace(index, nil, workspace_path, :ordsets.new())

    untracked
    |> Enum.sort()
    |> Enum.each(fn path ->
      IO.puts("?? #{path}")
    end)
  end

  @spec scan_workspace(Index.t(), Path.t(), Path.t(), list()) :: list()
  defp scan_workspace(index, dirname, workspace, untracked_list) do
    Workspace.list_dir(dirname, workspace)
    |> Enum.reduce(untracked_list, fn {file, stat}, untracked_list ->
      if Index.tracked?(index, file) do
        if stat.type == :directory do
          scan_workspace(index, file, workspace, untracked_list)
        else
          untracked_list
        end
      else
        if stat.type == :directory do
          # doing this circus, so that we don't have to worry about path separator in other OS
          # we get `file_path/` in unix and `file_path\` in windows ig.
          [file, _] = Path.join(file, " ") |> String.split(" ")
          :ordsets.add_element(file, untracked_list)
        else
          :ordsets.add_element(file, untracked_list)
        end
      end
    end)
  end
end
