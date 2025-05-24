defmodule Objects.Blob do
  @moduledoc """
  A Blob represent a file, thesea are the leaf nodes
  """
  @type t :: %__MODULE__{
          type: Object.object_type(),
          oid: String.t(),
          data: String.t(),
          mode: integer(),
          name: String.t()
        }
  defstruct [:oid, :data, :mode, :name, type: :blob]

  @doc """
  Creates a new Blob

  - data - The actual data in binary
  - name - Name of the file
  - mode - The file mode (100_644 default). Octal number in unix file system,
    which represents rw-r-r (owner, group, other) permissions
  - oid - Object Id - This is hash of the Blob (type + size + content). This is calculated when write the file to the Database
    using `Database.store()`
  """
  @spec new(binary(), String.t()) :: __MODULE__.t()
  def new(data, name, mode \\ 100_644, oid \\ nil) do
    %__MODULE__{}
    |> Map.merge(%{data: data, mode: mode, name: name, oid: oid})
  end

  defimpl Object do
    def oid(object) do
      object.oid
    end

    def type(object) do
      object.type
    end

    def mode(object) do
      object.mode
    end
  end

  defimpl String.Chars do
    def to_string(object) do
      object.data
    end
  end
end
