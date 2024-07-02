defmodule RalphTest do
  use ExUnit.Case
  doctest Ralph

  test "greets the world" do
    assert Ralph.hello() == :world
  end
end
