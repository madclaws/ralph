defmodule Objects.Index do
  @moduledoc false

  @type t :: %__MODULE__{
          type: Object.object_type(),
          oid: String.t() | nil,
          entries: %{String.t() => Object},
          mode: integer(),
          # index's path, .git/INDEX
          path: Path.t(),
          key_set: list()
        }
  defstruct [:oid, :mode, :path, :key_set, entries: %{}, type: :index]

  @max_path_size 0xFFF

  @spec new(Path.t()) :: __MODULE__.t()
  def new(path) do
    %__MODULE__{}
    |> Map.merge(%{path: path, key_set: :ordsets.new()})
  end

  @spec add(__MODULE__.t(), Path.t(), binary(), File.Stat.t()) :: __MODULE__.t()
  def add(index, pathname, oid, stat) do
    # We are using ordset so that we can make sure we are writing to
    # index in the filename order
    key_set = :ordsets.add_element(pathname, index.key_set)
    entry = create_entry(pathname, oid, stat)
    entries = Map.put(index.entries, pathname, entry)
    %{index | entries: entries, key_set: key_set}
  end

  @spec write_updates(__MODULE__.t()) :: __MODULE__.t()
  def write_updates(%__MODULE__{} = index) do
    # header
    # How we can pack mixed data into a binary, we can achieve similar to how
    # ruby does Array#pack, but this is with more granularity
    # for ex 2::32, packs 2 into a 32 bit, so it looks like <<0 0 0 2>>
    header = <<"DIRC"::binary, 2::32, Enum.count(index.entries)::32>>

    entry_bin =
      Enum.reduce(index.key_set, <<>>, fn k, bin ->
        bin <> serialize_entry(index.entries[k])
      end)

    index_hash = :crypto.hash(:sha, header <> entry_bin)
    Refs.update_index(header <> entry_bin <> index_hash, index.path)
  end

  @spec create_entry(Path.t(), binary(), File.Stat.t()) :: Aja.OrdMap.t()
  defp create_entry(pathname, oid, %File.Stat{} = stat) do
    flags = min(byte_size(pathname), @max_path_size)

    Aja.OrdMap.new(
      ctime: stat.ctime,
      # ignoring nanosec fraction, since we dont get it in elixir
      ctime_nsec: 0,
      mtime: stat.mtime,
      mtime_nsec: 0,
      dev: stat.major_device,
      ino: stat.inode,
      mode: stat.mode,
      uid: stat.uid,
      gid: stat.gid,
      size: stat.size,
      oid: oid,
      flags: flags,
      path: pathname
    )
  end

  @spec serialize_entry(Aja.OrdMap.t()) :: binary()
  defp serialize_entry(entry) do
    {_, entry_bin} =
      Enum.reduce_while(entry, {0, <<>>}, fn {_k, v}, acc_state ->
        {acc, bin_stat} = acc_state

        if acc + 1 == 10 do
          {:halt, {acc + 1, bin_stat <> <<v::32>>}}
        else
          {:cont, {acc + 1, bin_stat <> <<v::32>>}}
        end
      end)

    entry_bin =
      entry_bin <>
        (entry[:oid] |> Base.decode16!(case: :lower)) <> <<entry[:flags]::16>> <> entry[:path]

    repeated_null_bytes =
      if rem(byte_size(entry_bin), 8) == 0,
        do: 8,
        else: (8 - rem(byte_size(entry_bin), 8)) |> IO.inspect(label: :repeat_null_bytes)

    entry_bin <> String.duplicate("\0", repeated_null_bytes)
  end
end
