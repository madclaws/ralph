defmodule Database do
  @moduledoc """
  Store the file content in Git database format
  serialize data into git db format
  compress it and store it.
  """

  @doc """
  Creates the hash of the Object.t(), writes the Object to disk and return
  the Object.t() with oid (hash) in its struct

  object - Object.t(),
  db_path - The path where we store objects folder, normally .git/objects
  write? - Should we actually write the data to disk (true by default, for tests we need to be false)
  """
  @spec store(Object.t(), String.t(), write? :: boolean()) :: Object.t()
  def store(object, db_path, write? \\ true) do
    content =
      "#{Object.type(object)} #{byte_size(to_string(object))}\0#{to_string(object)}"

    oid = :crypto.hash(:sha, content) |> Base.encode16(case: :lower)

    if write? do
      write_object(oid, content, db_path)
    end

    %{object | oid: oid}
  end

  @doc """
  Objects are stored where oid is hash like AAFGBJJ then folder struct will be
  AA -> FGBJJ
  """
  @spec write_object(binary(), binary(), String.t()) :: any()
  def write_object(oid, content, db_path) do
    object_path =
      Path.join([
        db_path,
        String.slice(oid, 0..1),
        String.slice(oid, 2..(String.length(oid) - 1))
      ])

    if not File.exists?(object_path) do
      dirname = Path.dirname(object_path)

      temp_path = Path.join([dirname], generate_temp_obj_name())

      file =
        try do
          File.open!(temp_path, [:read, :write, :exclusive])
        rescue
          _ ->
            File.mkdir(dirname)
            File.open!(temp_path, [:read, :write, :exclusive])
        end

      compressed_content = compress(content)
      :ok = IO.binwrite(file, compressed_content)
      File.close(file)
      File.rename!(temp_path, object_path)
    else
      :ok
    end
  end

  @spec generate_temp_obj_name :: String.t()
  def generate_temp_obj_name do
    t = Enum.reduce(0..6, [], fn _d, li -> [Enum.random(97..122) | li] end) |> to_string
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    "temp_obj_#{t}_#{timestamp}"
  end

  @spec compress(binary()) :: binary()
  defp compress(content) do
    z = :zlib.open()
    :ok = :zlib.deflateInit(z, :best_speed)
    b = :zlib.deflate(z, content, :finish)
    :zlib.deflateEnd(z)
    :zlib.close(z)
    :erlang.list_to_binary(b)
  end
end
