defmodule Objects.Blob do
  @type t :: %__MODULE__{
          type: Object.object_type(),
          oid: String.t(),
          data: String.t(),
          mode: integer()
        }
  defstruct [:oid, :data, :mode, type: :blob]

  @spec new(binary()) :: __MODULE__.t()
  def new(data, mode \\ 100644) do
    %__MODULE__{}
    |> Map.merge(%{data: data, mode: mode})
  end

  defimpl Object do
    def oid(object) do
      object.oid
    end

    def type(object) do
      object.type
    end
  end

  defimpl String.Chars do
    def to_string(object) do
      object.data
    end
  end
end
