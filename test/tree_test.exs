defmodule TreeTest do
  alias Objects.Tree
  alias Objects.Blob
  use ExUnit.Case

  doctest Workspace

  @tag :build
  test "build/1" do
    children =
      [
        # Blob.new("a", "lib/a.ex"),
        # # {"lib.ex", Blob.new("lib")},
        # Blob.new("b", "lib/b.ex"),
        # Blob.new("c", "bin/c.ex"),
        # Blob.new("d", "bin/d.ex"),
        Blob.new("c", "c.ex"),
        Blob.new("d", "d.ex")
        # {"bin/zest.ex", Blob.new("zest")},
        # {"bin/b/arc.ex", Blob.new("arc")},
      ]
      |> Enum.map(&Database.store(&1, "NA", false))

    tree = Tree.build(children) |> IO.inspect(label: :build)
    IO.puts("\n\n\n")
    db_path = "/alo"
    db_fn = fn object -> Database.store(object, db_path, false) end

    tree = Tree.traverse(tree, db_fn) |> IO.inspect(label: :traverse)
    assert %Tree{} = tree = Database.store(tree, db_path, false) |> IO.inspect(label: :final_tree)
    # IO.inspect(tree.entries["lib"][:entries])
    # oid = tree.entries["lib"].entries["a.ex"].oid,     
    oid = tree.entries["c.ex"].oid
    Tree.traverse_proof(tree, oid, []) |> IO.inspect()
  end
end
