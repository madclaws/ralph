defmodule Workspace do
  @doc """
  Handles stuff in working tree
  """

  @spec list_files!(Path.t(), Path.t()) :: list()
  def list_files!(pathname, workspace_path) do
    if File.dir?(pathname) do
      do_list_files!(pathname, workspace_path)
      |> List.flatten()
    else
      [Path.relative_to(pathname, workspace_path)]
    end
  end

  @spec read_file(Path.t()) :: binary()
  def read_file(pathname) do
    File.read!(pathname)
  end

  @spec stat_file(Path.t()) :: map()
  def stat_file(pathname) do
    File.stat!(pathname, time: :posix)
  end

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
