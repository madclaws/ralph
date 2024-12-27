defmodule Workspace do
  @doc """
  Handles stuff in working tree
  """

  @spec list_files!(Path.t()) :: list()
  def list_files!(pathname) do
    File.ls!(pathname)
    |> Enum.filter(fn file -> file not in [".", "..", ".git"] end)
  end

  @spec read_file(Path.t()) :: binary()
  def read_file(pathname) do
    File.read!(pathname)
  end

  @spec stat_file(Path.t()) :: map()
  def stat_file(pathname) do
    File.stat!(pathname)
  end
end
