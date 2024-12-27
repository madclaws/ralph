defmodule Objects.Tree do
  @moduledoc """
  Tree object

  Tree generally saves with the detials of the blobs in
  the working directory
  """
  alias Objects.Blob

  @type children :: list(child())

  @type child :: {name :: String.t(), blob :: Blob.t()}

  @type t :: %__MODULE__{
          type: Object.object_type(),
          oid: String.t() | nil,
          children: children(),
          entries: map()
        }
  defstruct [:oid, :children, entries: %{}, type: :tree]

  @spec new(children()) :: __MODULE__.t()
  def new(children) do
    %__MODULE__{}
    |> Map.merge(%{children: children})
  end

  def new do
    %__MODULE__{}
  end

  @spec build(children()) :: __MODULE__.t()
  def build(children) do
    sorted_children = Enum.sort(children, &(elem(&1, 0) <= elem(&2, 0)))
    root = new()

    sorted_children
    |> Enum.reduce(root, fn {name, _blob} = child, root ->
      add_entry(root, Workspace.descend(name) |> Enum.drop(-1), child)
    end)
    |> IO.inspect()
  end

  @spec add_entry(__MODULE__.t(), list(), child()) :: __MODULE__.t()
  defp add_entry(tree, parent_dirs, {name, _blob} = child) do
    if Enum.empty?(parent_dirs) do
      entries = Map.put(tree.entries, Path.basename(name), child)
      %{tree | entries: entries}
    else
      [p | rest] = parent_dirs
      p = Path.basename(p)
      sub_tree = tree.entries[p] || new()
      sub_tree = add_entry(sub_tree, rest, child)
      entries = Map.put(tree.entries, p, sub_tree)
      %{tree | entries: entries}
    end
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
      |> Enum.map(fn {name, blob} ->
        # Base.decode16! converts the 40byte oid to 20byte
        "#{blob.mode} #{name}\0" <> Base.decode16!(blob.oid, case: :lower)
      end)
      |> Enum.join("")
    end
  end
end
