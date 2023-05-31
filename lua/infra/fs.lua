local M = {}

local uv = vim.loop
local api = vim.api

local fn = require("infra.fn")
local strlib = require("infra.strlib")
local jelly = require("infra.jellyfish")("infra.fs")

M.sep = "/"

--alternative to vim.fn.resolve
---@return string @the resolved file type
local function resolve_symlink_type(fpath)
  local function istype(mode, mask) return bit.band(mode, mask) == mask end
  local max_link_level = 8

  local next = fpath
  local remain = max_link_level
  while remain > 0 do
    remain = remain - 1

    next = uv.fs_realpath(next)
    local stat = uv.fs_stat(next)

    -- IFIFO  = 0o010000 -> 0x1000
    -- IFCHR  = 0o020000 -> 0x2000
    -- IFDIR  = 0o040000 -> 0x4000
    -- IFBLK  = 0o060000 -> 0x6000
    -- IFREG  = 0o100000 -> 0x8000
    -- IFLNK  = 0o120000 -> 0xa000
    -- IFSOCK = 0o140000 -> 0xc000

    local type
    if istype(stat.mode, 0xa000) then
      type = "link"
    elseif istype(stat.mode, 0x4000) then
      type = "directory"
    elseif bit.band(stat.mode, 0x8000) then
      type = "file"
    elseif bit.band(stat.mode, 0x1000) then
      type = "fifo"
    elseif bit.band(stat.mode, 0x2000) then
      type = "char"
    elseif bit.band(stat.mode, 0x6000) then
      type = "block"
    elseif bit.band(stat.mode, 0xc000) then
      type = "socket"
    else
      error(string.format("unexpected file type, mode=%s file=%s", stat.mode, fpath))
    end
    if type ~= "link" then return type end
  end

  error(string.format("too many levels symlink; file=%s, max=%d", fpath, max_link_level))
end

---@param root string @absolute path
---@param resolve_symlink nil|boolean @nil=true
---@return fun():string?,string? @iterator -> {basename, file-type}
function M.iterdir(root, resolve_symlink)
  local ok, scanner = pcall(uv.fs_scandir, root)
  if not ok then
    jelly.warn("failed to scan dir=%s, err=%s", root, scanner)
    return function() end
  end

  if scanner == nil then return function() end end

  -- must be set to true explictly
  if resolve_symlink == true then return function() return uv.fs_scandir_next(scanner) end end

  return function()
    local fname, ftype = uv.fs_scandir_next(scanner)
    if ftype ~= "link" then return fname, ftype end
    return fname, resolve_symlink_type(M.joinpath(root, fname))
  end
end

---@param ... string
---@return string
function M.joinpath(...)
  local args
  do
    args = { ... }
    if #args == 0 then return "" end
    if #args == 1 then return args[1] end
    -- no trailing /
    args[#args] = strlib.rstrip(args[#args], "/")
  end

  local parts
  do
    parts = args
    -- new root
    for i = #args, 2, -1 do
      if vim.startswith(args[i], "/") then
        parts = fn.slice(args, i, #args)
        break
      end
    end
  end

  local path
  do
    -- stole from: https://github.com/neovim/neovim/commit/189fb6203262340e7a59e782be970bcd8ae28e61#diff-fecfd503a1c28e0a28a91da0294b12dbc72f081cb12434459648a44f641b68d9
    path = fn.join(parts, "/")
    path = string.gsub(path, [[/+]], "/")
  end

  return path
end

function M.relative_path(root, subdir)
  if vim.endswith(root, "/") or vim.endswith(root, "/") then return end
  if root == subdir then return "" end
  if not vim.startswith(subdir, root) then return end
  return string.sub(subdir, #root + 2)
end

---@param path string
---@return boolean
function M.is_absolute(path)
  if not vim.startswith(path, "/") then return false end
  -- ..
  if strlib.find(path, "/../") then return false end
  if vim.endswith(path, "/..") then return false end
  -- .
  if strlib.find(path, "/./") then return false end
  if vim.endswith(path, "/.") then return false end

  return true
end

---@param plugin_name string
---@param fname string? default=init.lua
function M.resolve_plugin_root(plugin_name, fname)
  fname = fname or "init.lua"
  local files = api.nvim_get_runtime_file(M.joinpath("lua", plugin_name, fname), false)
  assert(files and #files == 1)
  return string.sub(files[1], 1, -(#fname + 2))
end

---@param path string @absolute path, no trailing `/`
---@return string
function M.parent(path)
  assert(path ~= "/", "root has no parent")
  assert(M.is_absolute(path), "path should be absolute")
  path = strlib.rstrip(path, "/")
  local found = assert(strlib.rfind(path, "/"))
  return string.sub(path, 1, found - 1)
end

return M
