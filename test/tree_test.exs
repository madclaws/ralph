defmodule TreeTest do
  alias Objects.Tree
  alias Objects.Blob
  use ExUnit.Case

  @tag :build
  test "build/1" do
    children = [
      # {"author.ex", Blob.new("author")},
      # {"lib.ex", Blob.new("lib")},
      {"bin/ralph.ex", Blob.new("ralph")},
      {"bin/zest.ex", Blob.new("zest")},
      {"bin/b/arc.ex", Blob.new("arc")},
    ]

    Tree.build(children)
  end
end
