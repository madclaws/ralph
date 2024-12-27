defmodule Objects.Commit do
  @type t :: %__MODULE__{
          type: Object.object_type(),
          oid: String.t(),
          tree_oid: String.t(),
          author: String.t(),
          message: String.t()
        }
  defstruct [:oid, :tree_oid, :author, :committer, :message, type: :commit]

  @spec new(String.t(), String.t(), String.t()) :: __MODULE__.t()
  def new(tree, author, message) do
    %__MODULE__{}
    |> Map.merge(%{tree_oid: tree, author: author, message: message})
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
      [
        "tree #{object.tree_oid}",
        "author #{object.author}",
        "committer #{object.author}",
        "",
        object.message
      ]
      |> Enum.join("\n")
    end
  end
end
