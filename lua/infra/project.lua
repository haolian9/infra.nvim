---provides project-related specs
local M = {}

local subprocess = require("infra.subprocess")
local prefer = require("infra.prefer")
local jelly = require("infra.jellyfish")("infra.project")
local fs = require("infra.fs")

local api = vim.api

local state = {
  ---@type {[string]: string} {path: git-root}
  git = {},
}

function M.working_root() return vim.fn.getcwd() end

---@param basedir string absolute path
---@return string?
local function resolve_git_root(basedir)
  local result = subprocess.run("git", { args = { "rev-parse", "--show-toplevel" }, cwd = basedir }, true)

  if result.exit_code ~= 0 then return jelly.warn("not in a git repo: %s", basedir) end

  local root = result.stdout()
  assert(root ~= nil and root ~= "")

  return root
end

---@param bufnr? number
---@return string?
function M.git_root(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()

  if prefer.bo(bufnr, "buftype") ~= "" then return jelly.err("not a regular buffer") end

  local basedir
  do
    local bufname = api.nvim_buf_get_name(bufnr)
    if bufname == "" then
      basedir = M.working_root()
    else
      basedir = fs.parent(vim.fn.fnamemodify(bufname, "%:p"))
    end
  end

  local root = state.git[basedir]
  if root == nil then
    -- cache the result if possible since it's an expensive operation
    local result = subprocess.run("git", { args = { "rev-parse", "--show-toplevel" }, cwd = basedir }, true)
    if result.exit_code ~= 0 then return jelly.warn("not in a git repo: %s", basedir) end
    root = result.stdout()
    assert(root ~= nil and root ~= "")
    state.git[basedir] = root
  end

  return root
end

return M
