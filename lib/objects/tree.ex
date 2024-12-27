defmodule Objects.Tree do
  @moduledoc """
  Tree object

  Tree generally saves with the detials of the blobs in
  the working directory
  """

  @type children :: list({name :: String.t(), oid :: String.t()})

  @type t :: %__MODULE__{
          type: Object.object_type(),
          oid: String.t() | nil,
          children: children(),
          mode: number()
        }
  defstruct [:oid, :data, :children, type: :tree, mode: 100_644]

  @spec new(children()) :: __MODULE__.t()
  def new(children) do
    %__MODULE__{}
    |> Map.merge(%{children: children})
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
      Enum.sort(object.children, &(elem(&1, 0) <= elem(&2, 0)))
      |> Enum.map(fn {name, oid} ->
        # Base.decode16! converts the 40byte oid to 20byte
        "#{object.mode} #{name}\0" <> Base.decode16!(oid, case: :lower)
      end)
      |> Enum.join("")
    end
  end
end
