defmodule Objects.Commit do
  @type t :: %__MODULE__{
          type: Object.object_type(),
          oid: String.t(),
          tree_oid: String.t(),
          author: String.t(),
          message: String.t(),
          parent: String.t() | nil
        }
  defstruct [:oid, :tree_oid, :author, :committer, :message, :parent, type: :commit]

  @spec new(String.t() | nil, String.t(), String.t(), String.t()) :: __MODULE__.t()
  def new(parent, tree, author, message) do
    %__MODULE__{}
    |> Map.merge(%{tree_oid: tree, author: author, message: message, parent: parent})
  end

  defimpl Object do
    def oid(object) do
      object.oid
    end

    def type(object) do
      object.type
    end

    # commit doesnt need mode, just a dummy impl
    def mode(_object) do
      0
    end
  end

  defimpl String.Chars do
    def to_string(object) do
      if is_binary(object.parent) do
        [
          "tree #{object.tree_oid}",
          "parent #{object.parent}",
          "author #{object.author}",
          "committer #{object.author}",
          "",
          object.message
        ]
      else
        [
          "tree #{object.tree_oid}",
          "author #{object.author}",
          "committer #{object.author}",
          "",
          object.message
        ]
      end
      |> Enum.join("\n")
    end
  end
end
