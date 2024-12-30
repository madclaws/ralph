defmodule Objects.Index do
  @moduledoc false

  @type t :: %__MODULE__{
          type: Object.object_type(),
          oid: String.t() | nil,
          entries: %{String.t() => Object},
          mode: integer(),
          # index's path, .git/INDEX
          path: Path.t(),
          key_set: list(),
          # Changes after index loaded to memory
          changed: boolean()
        }
  defstruct [:oid, :mode, :path, :key_set, entries: %{}, type: :index, changed: false]

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
    %{index | entries: entries, key_set: key_set, changed: true}
  end

  @spec write_updates(__MODULE__.t()) :: __MODULE__.t()
  def write_updates(%__MODULE__{changed: false} = index), do: index

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
    %{index | changed: false}
  end

  @spec load(__MODULE__.t()) :: __MODULE__.t()
  def load(%__MODULE__{} = index) do
    clear(index)

    try do
      file = open_index_file(index)
      entry_count = read_header(file)
      index = read_entries(index, file, entry_count)
      File.close(file)
      index
    rescue
      _err ->
        index
    end
  end

  @spec clear(__MODULE__.t()) :: __MODULE__.t()
  defp clear(index) do
    %{index | entries: %{}, key_set: :ordsets.new(), changed: false}
  end

  @spec read_header(IO.device()) :: integer()
  defp read_header(file) do
    header_bin = IO.binread(file, 12)
    <<"DIRC"::binary, 2::32, count::32>> = header_bin

    count
  end

  @spec open_index_file(__MODULE__.t()) :: IO.device()
  defp open_index_file(index) do
    File.open!(index.path, [:read])
  end

  @spec read_entries(__MODULE__.t(), IO.device(), integer()) :: any()
  defp read_entries(index, file, entry_count) do
    Enum.reduce(0..(entry_count - 1), index, fn _, index ->
      min_size = 64
      min_block = 8
      entry = IO.binread(file, min_size)

      entry = read_until_null(file, entry, min_block)
      entry = deserialize_entry(entry)
      key_set = :ordsets.add_element(entry[:path], index.key_set)
      entries = Map.put(index.entries, entry[:path], entry)
      %{index | entries: entries, key_set: key_set}
    end)
  end

  @spec read_until_null(IO.device(), binary(), integer()) :: binary()
  defp read_until_null(file, entry, min_block) do
    if :binary.last(entry) != 0 do
      entry = entry <> IO.binread(file, min_block)
      read_until_null(file, entry, min_block)
    else
      entry
    end
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
        else: 8 - rem(byte_size(entry_bin), 8)

    entry_bin <> String.duplicate("\0", repeated_null_bytes)
  end

  @spec deserialize_entry(binary()) :: Aja.OrdMap.t()
  defp deserialize_entry(bin_entry) do
    <<ctime::32, _ctime_nsec::32, mtime::32, _mtime_nsec::32, dev::32, ino::32, mode::32, uid::32,
      gid::32, size::32, oid::160, flags::16,
      rest::binary>> =
      bin_entry

    # whatever before null byte
    [path, _] = :binary.split(rest, <<0>>)

    Aja.OrdMap.new(
      ctime: ctime,
      # ignoring nanosec fraction, since we dont get it in elixir
      ctime_nsec: 0,
      mtime: mtime,
      mtime_nsec: 0,
      dev: dev,
      ino: ino,
      mode: mode,
      uid: uid,
      gid: gid,
      size: size,
      oid: oid |> Integer.to_string(16) |> String.downcase(),
      flags: flags,
      path: path
    )
  end
end
