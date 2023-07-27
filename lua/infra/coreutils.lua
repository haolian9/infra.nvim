-- prefer uv.fs_* than vim.fn.*

local M = {}

local api = vim.api
local uv = vim.loop

local bufpath = require("infra.bufpath")
local bufrename = require("infra.bufrename")
local ex = require("infra.ex")
local fs = require("infra.fs")
local jelly = require("infra.jellyfish")("infra.coreutils")

---@param fname string
---@param root ?string @root for fname
---@param open_cmd ?string @vs, sp, e, tabe ...
function M.relative_edit(fname, root, open_cmd)
  assert(fname ~= nil and fname ~= "")
  root = root or vim.fn.expand("%:p:h")
  open_cmd = open_cmd or "split"

  ex(open_cmd, fs.joinpath(root, fname))
end

function M.touch(fpath)
  local file, err = uv.fs_open(fpath, "a", tonumber("600", 8))
  if err ~= nil then error(err) end
  uv.fs_close(file)
end

function M.rm_filebuf(bufnr)
  if bufnr == nil or bufnr == 0 then bufnr = api.nvim_get_current_buf() end

  local path = bufpath.file(bufnr, true)
  if path ~= nil then
    local _, errmsg = uv.fs_unlink(path)
    if errmsg then return jelly.err(errmsg) end
  end

  api.nvim_buf_delete(bufnr, { force = true })
  jelly.info("removed file: %s, buf: %s", path, bufnr)
end

function M.rename_filebuf(bufnr, fname)
  assert(fname ~= nil and fname ~= "")
  if bufnr == nil or bufnr == 0 then bufnr = api.nvim_get_current_buf() end

  local path = bufpath.file(bufnr, true)

  local newpath
  do
    if path ~= nil then
      newpath = fs.joinpath(fs.parent(path), fname)
    else
      newpath = fname
    end
    if path == newpath then return jelly.debug("same name") end
  end

  if path ~= nil then -- the buf being renamed is a real file
    local _, errmsg = uv.fs_rename(path, newpath)
    if errmsg then return jelly.err(errmsg) end
  end

  bufrename(bufnr, newpath)
  jelly.info("renamed to %s", newpath)
end

---@return string
function M.whoami() return tostring(uv.getuid()) end

---@param path string @absolute path
---@param mode ?number @default 0o700
---@param exists_ok ?boolean @default true
---@return boolean
function M.mkdir(path, mode, exists_ok)
  mode = mode or tonumber("700", 8)
  local _ = exists_ok

  -- uv.fs_mkdir did not support `p` flag
  local suc = vim.fn.mkdir(path, "p", mode)
  return suc == 1
end

---@param relpath string @relative path
---@param mode ?number @default 0o700
---@param exists_ok ?boolean @default true
function M.relative_mkdir(relpath, mode, exists_ok)
  mode = mode or tonumber("700", 8)
  if exists_ok == nil then exists_ok = true end

  local bufnr = api.nvim_get_current_buf()
  local basepath = bufpath.dir(bufnr)
  local path = fs.joinpath(basepath, relpath)

  return M.mkdir(path, mode, exists_ok)
end

return M
