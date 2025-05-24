defmodule TreeTest do
  alias Objects.Tree
  alias Objects.Blob
  use ExUnit.Case

  doctest Workspace

  @tag :build
  test "build/1" do
    children = [
      Blob.new("author", "lib/author.ex"),
      # {"lib.ex", Blob.new("lib")},
      # Blob.new("ralph", "bin/ralph.ex")
      # {"bin/zest.ex", Blob.new("zest")},
      # {"bin/b/arc.ex", Blob.new("arc")},
    ]

    tree = Tree.build(children)
    IO.puts("\n\n\n")
    db_path = "/alo"
    db_fn = fn _object -> db_path <> "#{Enum.random(0..10)}" end
    Tree.traverse(tree, db_fn)
  end
end
