defmodule Workspace do
  @doc """
  Handles stuff in working tree
  """

  @spec list_files!(String.t()) :: list()
  def list_files!(pathname) do
    File.ls!(pathname)
    |> Enum.filter(fn file -> file not in [".", "..", ".git"] end)
  end

  @spec read_file(String.t()) :: binary()
  def read_file(pathname) do
    File.read!(pathname)
  end
end
