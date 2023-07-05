local M = require("infra.fs")

local function test_0()
  do
    local root = "/dev"
    local iter = M.iterdir(root)
    local count = 0
    for _ in iter do
      count = count + 1
    end
    assert(count > 1, "/dev can not be empty")
  end
  do
    local root = "/tmp"
    local iter = M.iterdir(root)
    local count = 0
    for _ in iter do
      count = count + 1
    end
    assert(count > 1, "/tmp can not be empty")
  end
  do
    local root = "/"
    local iter = M.iterdir(root)
    local count = 0
    for _ in iter do
      count = count + 1
    end
    assert(count > 1, "/ can not be empty")
  end
  do
    local root = "/root"
    local iter = M.iterdir(root)
    local count = 0
    for _ in iter do
      count = count + 1
    end
    assert(count == 0, "normal user can not ls /root")
  end
end

local function test_1()
  do
    local joined = M.joinpath("/a/", "/b/", "c/")
    assert(joined == "/b/c")
  end
  do
    local joined = M.joinpath("/", "boot/")
    assert(joined == "/boot")
  end
  do
    local joined = M.joinpath("", "/boot/")
    assert(joined == "/boot")
  end
end

local function test_2()
  do
    local rel = M.relative_path("/a/b", "/a/b")
    assert(rel == "")
  end
  do
    local rel = M.relative_path("/a/", "/a/b")
    assert(rel == nil)
  end
  do
    local rel = M.relative_path("/a/b", "/a")
    assert(rel == nil)
  end
  do
    local rel = M.relative_path("/a", "/a/b")
    assert(rel == "b")
  end
  do
    local rel = M.relative_path("/a/b", "/a/b")
    assert(rel == "")
  end
end

local function test_3()
  assert(M.shorten("/") == "/")
  assert(M.shorten("/foo") == "/foo")
  assert(M.shorten("/foo/bar/test.lua") == "/f/bar/test.lua")
  assert(M.shorten("/foo/bar/baz/test.lua") == "/f/b/baz/test.lua")
  assert(M.shorten("foo/bar/baz/test.lua") == "f/b/baz/test.lua")
  assert(M.shorten("test.lua") == "test.lua")
end

test_0()
test_1()
test_2()
test_3()
