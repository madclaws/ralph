defmodule Workspace do
  @doc """
  Handles stuff in working tree
  """

  @spec list_files!(Path.t(), Path.t()) :: list()
  def list_files!(pathname, workspace_path) do
    relative = Path.relative_to(pathname, workspace_path)

    cond do
      File.dir?(pathname) ->
        do_list_files!(pathname, workspace_path)
        |> List.flatten()

      File.exists?(pathname) ->
        [relative]

      true ->
        raise "MissingFile: pathspec '#{relative}' did not match any files"
    end
  end

  @spec list_dir(Path.t(), Path.t()) :: %{String.t() => File.Stat.t()}
  def list_dir(dirname, workspace) do
    dir_abs_path = Path.join(workspace, dirname || "")

    File.ls!(dir_abs_path)
    |> Enum.filter(fn file -> file not in [".", "..", ".git"] end)
    |> Enum.reduce(%{}, fn file, file_stat ->
      relative = Path.relative_to(Path.join(dir_abs_path, file), workspace)
      stat = File.stat!(Path.join(dir_abs_path, file))
      Map.put(file_stat, relative, stat)
    end)
  end

  @spec read_file(Path.t()) :: binary()
  def read_file(pathname) do
    File.read!(pathname)
  rescue
    _err ->
      raise "No Permission: open #{pathname}, permission denied"
  end

  @spec stat_file(Path.t()) :: map()
  def stat_file(pathname) do
    File.stat!(pathname, time: :posix)
  rescue
    _err ->
      raise "No Permission: stat #{pathname}, permission denied"
  end

  @doc """
  Returns a list of paths from each hierarchy as we descend from root of the pathname to the full pathname

  ## Examples
    iex> Workspace.descend("bin/lib/author.ex")
    ["bin", "bin/lib", "bin/lib/author.ex"]
  """
  @spec descend(Path.t(), list()) :: list(Path.t())
  def descend(pathname, paths \\ []) do
    case Path.split(pathname) do
      [] ->
        paths

      [p] ->
        [p | paths]

      path_split ->
        rest = Enum.drop(path_split, -1)
        descend(rest |> Path.join(), [pathname | paths])
    end
  end

  @spec list_files!(Path.t(), Path.t()) :: list()
  defp do_list_files!(pathname, workspace_path) do
    files =
      File.ls!(pathname)
      |> Enum.filter(fn file -> file not in [".", "..", ".git"] end)

    Enum.map(files, fn file ->
      if File.dir?(Path.join(pathname, file)) do
        list_files!(Path.join(pathname, file), workspace_path)
      else
        Path.relative_to(Path.join(pathname, file), workspace_path)
      end
    end)
  end
end
