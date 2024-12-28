defmodule Objects.Blob do
  @type t :: %__MODULE__{
          type: Object.object_type(),
          oid: String.t(),
          data: String.t(),
          mode: integer(),
          name: String.t()
        }
  defstruct [:oid, :data, :mode, :name, type: :blob]

  @spec new(binary(), String.t()) :: __MODULE__.t()
  def new(data, name, mode \\ 100_644) do
    %__MODULE__{}
    |> Map.merge(%{data: data, mode: mode, name: name})
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
