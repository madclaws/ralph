defmodule Database do
  @moduledoc """
  Store the file content in Git database format
  serialize data into git db format
  compress it and store it.
  """

  @doc """
  serialize ex
  blob 6content
  compress
  write to correct folder
  """
  @spec store(Object.t(), String.t()) :: Object.t()
  def store(object, db_path) do
    content =
      "#{Object.type(object)} #{byte_size(to_string(object))}\0#{to_string(object)}"

    oid = :crypto.hash(:sha, content) |> Base.encode16(case: :lower)
    write_object(oid, content, db_path)
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
