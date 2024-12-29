defmodule Refs do
  @moduledoc """
  Module for handling refs

  such as .git/refs, .git/HEAD
  """
  alias Objects.Commit

  @spec update_head(Commit.t(), Path.t()) :: :ok | any()
  def update_head(commit, ralph_path) do
    file = File.open!(get_head_path(ralph_path), [:write])
    IO.write(file, commit.oid)
    File.close(file)
  end

  @spec read_head(Path.t()) :: String.t() | nil
  def read_head(ralph_path) do
    if File.exists?(get_head_path(ralph_path)) do
      File.read!(get_head_path(ralph_path))
    end
  end

  @spec update_index(binary(), Path.t()) :: :ok | any()
  def update_index(entry, ralph_path) do
    file = File.open!(ralph_path, [:append])
    IO.binwrite(file, entry)
    File.close(file)
  end

  @spec get_head_path(Path.t()) :: Path.t()
  defp get_head_path(ralph_path) do
    Path.join([ralph_path, "HEAD"])
  end
end
