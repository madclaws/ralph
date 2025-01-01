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
          changed: boolean(),
          parents: map()
        }
  defstruct [
    :oid,
    :mode,
    :path,
    :key_set,
    entries: %{},
    type: :index,
    changed: false,
    parents: %{}
  ]

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
    index = discard_conflicts(index, pathname)
    entry = create_entry(pathname, oid, stat)
    store_entry(index, pathname, entry)
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

  @spec tracked?(__MODULE__.t(), Path.t()) :: boolean()
  def tracked?(index, path) do
    Map.has_key?(index.entries, path) or Map.has_key?(index.parents, path)
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
      store_entry(index, entry[:path], entry)
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

  @spec discard_conflicts(__MODULE__.t(), Path.t()) :: any()
  defp discard_conflicts(index, pathname) do
    Workspace.descend(pathname)
    |> Enum.drop(-1)
    |> Enum.reduce(index, fn path, index ->
      remove_entry(index, path)
    end)
    |> remove_children(pathname)
  end

  @spec store_entry(__MODULE__.t(), Path.t(), Aja.OrdMap.t()) :: __MODULE__.t()
  defp store_entry(index, pathname, entry) do
    key_set = :ordsets.add_element(pathname, index.key_set)
    entries = Map.put(index.entries, pathname, entry)

    parents =
      Workspace.descend(pathname)
      |> Enum.drop(-1)
      |> Enum.reduce(index.parents, fn path, parents ->
        if Map.has_key?(parents, path) do
          entry_set = parents[path]
          entry_set = :ordsets.add_element(pathname, entry_set)
          Map.put(parents, path, entry_set)
        else
          :ordsets.new()
          |> then(&:ordsets.add_element(pathname, &1))
          |> then(&Map.put(parents, path, &1))
        end
      end)

    %{index | entries: entries, key_set: key_set, changed: true, parents: parents}
  end

  @spec remove_entry(__MODULE__.t(), Path.t()) :: __MODULE__.t()
  defp remove_entry(index, path) do
    entry = index.entries[path]

    if is_nil(entry) do
      index
    else
      key_set = :ordsets.del_element(entry[:path], index.key_set)
      entries = Map.delete(index.entries, entry[:path])

      parents =
        Workspace.descend(entry[:path])
        |> Enum.drop(-1)
        |> Enum.reduce(index.parents, fn parent_path, parents ->
          entry_set = parents[parent_path]
          entry_set = :ordsets.del_element(entry[:path], entry_set)

          if :ordsets.is_empty(entry_set) do
            Map.delete(parents, parent_path)
          else
            Map.put(parents, parent_path, entry_set)
          end
        end)

      %{index | key_set: key_set, entries: entries, parents: parents}
    end
  end

  @spec remove_children(__MODULE__.t(), Path.t()) :: __MODULE__.t()
  defp remove_children(index, path) do
    if Map.has_key?(index.parents, path) do
      children = index.parents[path]

      Enum.reduce(children, index, fn child, index ->
        remove_entry(index, child)
      end)
    else
      index
    end
  end
end
