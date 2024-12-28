defmodule Objects.Index do
  @moduledoc false

  @type t :: %__MODULE__{
          type: Object.object_type(),
          oid: String.t() | nil,
          entries: %{String.t() => Object},
          mode: integer(),
          # index's path, .git/INDEX
          path: Path.t()
        }
  defstruct [:oid, :mode, :path, entries: %{}, type: :index]

  @max_path_size 0xFFF
  @type entry :: %{
          ctime: integer(),
          ctime_nsec: integer(),
          mtime: integer(),
          mtime_nsec: integer(),
          dev: integer(),
          ino: integer(),
          mode: integer(),
          uid: integer(),
          gid: integer(),
          size: integer(),
          oid: integer(),
          flags: integer(),
          path: Path.t()
        }
  @spec new(Path.t()) :: __MODULE__.t()
  def new(path) do
    %__MODULE__{}
    |> Map.merge(%{path: path})
  end

  @spec add(__MODULE__.t(), Path.t(), binary(), File.Stat.t()) :: __MODULE__.t()
  def add(index, pathname, oid, stat) do
    entry = create_entry(pathname, oid, stat)
    entries = Map.put(index.entries, pathname, entry)
    %{index | entries: entries}
  end

  @spec write_updates(__MODULE__.t()) :: __MODULE__.t()
  def write_updates(%__MODULE__{} = index) do
    # header
    # How we can pack mixed data into a binary, we can achieve similar to how
    # ruby does Array#pack with more granularity
    # for ex 2::32, packs 2 into a 32 bit, so it looks like <<0 0 0 2>>
    header = <<"DIRC"::binary, 2::32, Enum.count(index.entries)::32>>
  end

  @spec create_entry(Path.t(), binary(), File.Stat.t()) :: entry()
  defp create_entry(pathname, oid, %File.Stat{} = stat) do
    flags = min(byte_size(pathname), @max_path_size)

    %{
      ctime: stat.ctime,
      ctime_nsec: 0,
      mtime: stat.mtime,
      mtime_nsec: 0,
      dev: stat.major_device,
      ino: stat.inode,
      gid: stat.gid,
      size: stat.size,
      oid: oid,
      flags: flags,
      path: pathname
    }
  end
end
