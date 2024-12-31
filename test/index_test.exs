defmodule IndexTest do
  @moduledoc false
  alias Objects.Index

  use ExUnit.Case

  @tag :index
  test "add index" do
    index = Index.new(Path.expand("."))

    index =
      Index.add(index, "abc.txt", "hex", %File.Stat{
        size: 989,
        type: :regular,
        access: :read_write,
        atime: 1_735_286_098,
        mtime: 1_735_286_097,
        ctime: 1_735_286_097,
        mode: 33188,
        links: 1,
        major_device: 16_777_233,
        minor_device: 0,
        inode: 34_855_644,
        uid: 501,
        gid: 20
      })

    assert ["abc.txt"] = Map.keys(index.entries)
  end

  @tag :index
  test "replace file with directory" do
    index = Index.new(Path.expand("."))

    index =
      Index.add(index, "abc.txt", "hex", %File.Stat{
        size: 989,
        type: :regular,
        access: :read_write,
        atime: 1_735_286_098,
        mtime: 1_735_286_097,
        ctime: 1_735_286_097,
        mode: 33188,
        links: 1,
        major_device: 16_777_233,
        minor_device: 0,
        inode: 34_855_644,
        uid: 501,
        gid: 20
      })

    index =
      Index.add(index, "abc.txt/c.txt", "hex", %File.Stat{
        size: 989,
        type: :regular,
        access: :read_write,
        atime: 1_735_286_098,
        mtime: 1_735_286_097,
        ctime: 1_735_286_097,
        mode: 33188,
        links: 1,
        major_device: 16_777_233,
        minor_device: 0,
        inode: 34_855_644,
        uid: 501,
        gid: 20
      })

    assert ["abc.txt/c.txt"] = Map.keys(index.entries)
  end

  @tag :index
  test "replace directory with a file" do
    index = Index.new(Path.expand("."))

    index =
      Index.add(index, "alice.txt", "hex", %File.Stat{
        size: 989,
        type: :regular,
        access: :read_write,
        atime: 1_735_286_098,
        mtime: 1_735_286_097,
        ctime: 1_735_286_097,
        mode: 33188,
        links: 1,
        major_device: 16_777_233,
        minor_device: 0,
        inode: 34_855_644,
        uid: 501,
        gid: 20
      })

    index =
      Index.add(index, "nested/bob.txt", "hex", %File.Stat{
        size: 989,
        type: :regular,
        access: :read_write,
        atime: 1_735_286_098,
        mtime: 1_735_286_097,
        ctime: 1_735_286_097,
        mode: 33188,
        links: 1,
        major_device: 16_777_233,
        minor_device: 0,
        inode: 34_855_644,
        uid: 501,
        gid: 20
      })

    index =
      Index.add(index, "nested/inner/charlie.txt", "hex", %File.Stat{
        size: 989,
        type: :regular,
        access: :read_write,
        atime: 1_735_286_098,
        mtime: 1_735_286_097,
        ctime: 1_735_286_097,
        mode: 33188,
        links: 1,
        major_device: 16_777_233,
        minor_device: 0,
        inode: 34_855_644,
        uid: 501,
        gid: 20
      })

    index =
      Index.add(index, "nested", "hex", %File.Stat{
        size: 989,
        type: :regular,
        access: :read_write,
        atime: 1_735_286_098,
        mtime: 1_735_286_097,
        ctime: 1_735_286_097,
        mode: 33188,
        links: 1,
        major_device: 16_777_233,
        minor_device: 0,
        inode: 34_855_644,
        uid: 501,
        gid: 20
      })

    assert ["alice.txt", "nested"] = Map.keys(index.entries)
  end
end
