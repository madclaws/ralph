defmodule WorkspaceTest do
  use ExUnit.Case

  @test_cases [
    {"/a/b/c", ["/", "/a", "/a/b", "/a/b/c"]},
    {"/", ["/"]},
    {"", []},
    {"/a", ["/", "/a"]},
    {"a/b/c", ["a", "a/b", "a/b/c"]},
    {"/a//b/c", ["/", "/a", "/a/b", "/a//b/c"]}
  ]

  @tag :desc
  test "test descend/2" do
    for {input, output} <- @test_cases do
      assert Workspace.descend(input) == output
    end
  end
end
