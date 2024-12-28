defmodule TreeTest do
  alias Objects.Tree
  alias Objects.Blob
  use ExUnit.Case

  @tag :build
  test "build/1" do
    children = [
      Blob.new("author", "author.ex"),
      # {"lib.ex", Blob.new("lib")},
      Blob.new("ralph", "bin/ralph.ex")
      # {"bin/zest.ex", Blob.new("zest")},
      # {"bin/b/arc.ex", Blob.new("arc")},
    ]

    tree = Tree.build(children) |> IO.inspect()
    IO.puts("\n\n\n")
    db_path = "/alo"
    db_fn = fn _object -> (db_path <> "#{Enum.random(0..10)}") |> IO.inspect() end
    Tree.traverse(tree, db_fn) |> IO.inspect(label: :traversed_tree)
  end
end
