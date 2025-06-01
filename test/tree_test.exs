defmodule TreeTest do
  alias Objects.Tree
  alias Objects.Blob
  use ExUnit.Case

  doctest Workspace

  @tag :build
  test "build/1" do
    children =
      [
        Blob.new("a", "a.ex"),
        # # {"lib.ex", Blob.new("lib")},
        # Blob.new("b", "lib/b.ex"),
        # Blob.new("c", "bin/c.ex"),
        # Blob.new("d", "bin/d.ex"),
        Blob.new("b", "b.ex")
        # Blob.new("d", "d.ex"), 
        # Blob.new("a", "lib/bin/a.ex"),
        # {"bin/zest.ex", Blob.new("zest")},
        # {"bin/b/arc.ex", Blob.new("arc")},
      ]

    test_3 = [
      Blob.new("a", "lib/a.ex"),
      Blob.new("b", "lib/b.ex"),
      Blob.new("c", "bin/c.ex"),
      Blob.new("d", "bin/d.ex")
    ]

    test_2 = [
      # NOT WORKING
      Blob.new("d", "d.ex"),
      Blob.new("a", "lib/bin/a.ex")
    ]

    children =
      test_3
      |> Enum.map(&Database.store(&1, "NA", false))

    tree = Tree.build(children)
    IO.puts("\n\n\n")
    db_path = "/alo"
    db_fn = fn object -> Database.store(object, db_path, false) end

    tree = Tree.traverse(tree, db_fn)
    assert %Tree{} = tree = Database.store(tree, db_path, false)
    # IO.inspect(tree.entries["lib"][:entries])
    oid = tree.entries["lib"].entries["a.ex"].oid
    # oid = tree.entries["d.ex"].oid
    # oid = tree.entries["lib"].entries["a.ex"].oid
    {_, _, prf} = Tree.generate_proof(tree, oid)
    assert length(prf) == 2
    {_, _, prf} = Tree.generate_proof(tree, "random")
    assert length(prf) == 0
  end
end
