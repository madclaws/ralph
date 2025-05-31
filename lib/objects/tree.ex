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

  @doc """
  Traverse the tree created by `Tree.build()` and creates hashes for the respective
  internal tree. This is how we create merkle tree.

  So we go through each entry of the tree, for each entry
  if the entry is a Tree itself we again call same function `traverse`
  For a Tree, after iterating through its leaf nodes/Blobs we create the oid for
  the tree and update the tree in its Parent's `entries`
  """
  @spec traverse(__MODULE__.t(), action :: function()) :: __MODULE__.t()
  def traverse(tree, action) do
    Enum.reduce(tree.entries, tree, fn {name, entry}, parent_tree ->
      entry =
        if is_struct(entry, __MODULE__) do
          traverse(entry, action)
        else
          entry
        end

      if is_struct(entry, __MODULE__) do
        # What we do here is basically create the oid (hash) for the tree and write that to disk
        entry = action.(entry)
        sub_entries = Map.put(parent_tree.entries, name, entry)
        Map.put(parent_tree, :entries, sub_entries)
      else
        parent_tree
      end
    end)
  end

  # def traverse_proof(_, _, result) when not is_nil(result), do: result
  def traverse_proof(tree, search_oid, has_found \\ false, prf_list \\ []) do
    # |> IO.inspect(label: :traverse_res)
    find_piblings(tree, search_oid,has_found, prf_list)
  end

  # TODO: Enum.reduce_while for early exit as opt
  defp do_traverse_proof(tree, search_oid, has_found, prf_list) do
    Enum.reduce(tree.entries, {search_oid, has_found, prf_list}, fn
      {_name, entry}, {search_oid, false = has_found, prf_list} = _res ->
        if is_struct(entry, __MODULE__) do
          find_piblings(entry, search_oid, has_found, prf_list)
        else
          if entry.oid == search_oid do
            {search_oid, true, prf_list}
          else
            {search_oid, has_found, prf_list}
          end
        end

      # |> IO.inspect(label: :end_reducer)

      {_, _}, {_, true, _} = res ->
        res
    end)
  end

  @spec find_piblings(Object.t(), binary(), boolean(), list()) ::
          {search_oid :: binary(), has_found :: boolean(), prf_list :: list()}
  defp find_piblings(entry, search_oid, has_found, prf_list) do
    case do_traverse_proof(entry, search_oid, has_found, prf_list) do
      {search_oid, true, prf_list} ->
        list =
          Enum.reduce(entry.entries, [], fn {_, child}, prfs ->
            if child.oid != search_oid do
              prfs ++ [child.oid]
            else
              prfs
            end
          end)

        {entry.oid, true, prf_list ++ list}

      res ->
        res
    end
  end

  # Recursively adds Blobs to the tree
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
