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
          entries: %{String.t() => Object},
          mode: integer()
        }
  defstruct [:oid, entries: %{}, type: :tree, mode: 40000]

  def new do
    %__MODULE__{}
  end

  @doc """
  Builds a hierarchial tree in the entries key

  This tree will be later traversed for building the merkle tree or snapshot of the commit 
  """
  @spec build(list(Blob.t())) :: __MODULE__.t()
  def build(children) do
    root = new()

    children
    |> Enum.reduce(root, fn child_blob, root ->
      add_entry(root, Workspace.descend(child_blob.name) |> Enum.drop(-1), child_blob)
    end)
  end

  @spec traverse(__MODULE__.t(), action :: function()) :: any()
  def traverse(tree, action) do
    Enum.reduce(tree.entries, tree, fn {name, entry}, parent_tree ->
      entry =
        if is_struct(entry, __MODULE__) do
          traverse(entry, action)
        else
          entry
        end

      if is_struct(entry, __MODULE__) do
        entry = action.(entry)
        sub_entries = Map.put(parent_tree.entries, name, entry)
        Map.put(parent_tree, :entries, sub_entries)
      else
        parent_tree
      end
    end)
  end

  @spec add_entry(__MODULE__.t(), list(), Blob.t()) :: __MODULE__.t()
  defp add_entry(tree, parent_dirs, child_blob) do
    if Enum.empty?(parent_dirs) do
      entries = Map.put(tree.entries, Path.basename(child_blob.name), child_blob)
      %{tree | entries: entries}
    else
      [p | rest] = parent_dirs
      p = Path.basename(p)
      sub_tree = tree.entries[p] || new()
      sub_tree = add_entry(sub_tree, rest, child_blob)
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

    def mode(object) do
      object.mode
    end
  end

  defimpl String.Chars do
    def to_string(object) do
      Enum.map(object.entries, fn {name, object} ->
        # Base.decode16! converts the 40byte oid to 20byte
        "#{Object.mode(object)} #{name}\0" <> Base.decode16!(Object.oid(object), case: :lower)
      end)
      |> Enum.join("")
    end
  end
end
