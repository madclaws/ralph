defmodule CommandsTest do
  @moduledoc false

  use ExUnit.Case

  setup do
    test_path = Path.expand(".") |> then(&Path.join([&1, "test/test_files"]))
    File.mkdir_p!(test_path)
    Commands.init(test_path)

    on_exit(fn ->
      File.rm_rf(test_path)
    end)

    {:ok, %{test_path: test_path}}
  end

  @tag :status
  test "lists files as untracked if they are not in the index", meta do
    File.touch(Path.join([meta.test_path, "h.txt"]))
    Commands.add([meta.test_path], meta.test_path)
    assert ExUnit.CaptureIO.capture_io(fn -> Commands.status(meta.test_path) end) == ""
    File.touch(Path.join([meta.test_path, "n.txt"]))
    assert ExUnit.CaptureIO.capture_io(fn -> Commands.status(meta.test_path) end) == "?? n.txt\n"
  end

  @tag :status_a
  test "list untracked directories not their content", meta do
    File.touch(Path.join([meta.test_path, "n.txt"]))
    File.mkdir_p!(Path.join([meta.test_path, "dir"]))
    File.touch(Path.join([meta.test_path, "dir/an.txt"]))

    assert ExUnit.CaptureIO.capture_io(fn -> Commands.status(meta.test_path) end) ==
             "?? dir/\n?? n.txt\n"
  end

  @tag :status_a
  test "list untracked files inside tracked directories", meta do
    File.mkdir_p!(Path.join([meta.test_path, "a/b"]))
    File.touch(Path.join([meta.test_path, "a/b/inner.txt"]))
    Commands.add([meta.test_path], meta.test_path)
    File.touch(Path.join([meta.test_path, "a/outer.txt"]))
    File.mkdir_p!(Path.join([meta.test_path, "a/b/c"]))
    File.touch(Path.join([meta.test_path, "a/b/c/file.txt"]))

    assert ExUnit.CaptureIO.capture_io(fn -> Commands.status(meta.test_path) end) ==
             "?? a/b/c/\n?? a/outer.txt\n"
  end

  @tag :skip
  test "doesn't list empty untracked directories", meta do
    File.mkdir_p!(Path.join([meta.test_path, "outer"]))

    assert ExUnit.CaptureIO.capture_io(fn -> Commands.status(meta.test_path) end) ==
             ""
  end

  @tag :skip
  test "lists untracked directories that indirectly contain files", meta do
    File.mkdir_p!(Path.join([meta.test_path, "outer/inner"]))
    File.touch(Path.join([meta.test_path, "outer/inner/file.txt"]))

    assert ExUnit.CaptureIO.capture_io(fn -> Commands.status(meta.test_path) end) ==
             "?? outer/\n"
  end
end
