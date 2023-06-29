---provides project-related specs
local M = {}

local fs = require("infra.fs")
local jelly = require("infra.jellyfish")("infra.project")
local prefer = require("infra.prefer")
local subprocess = require("infra.subprocess")

local api = vim.api
local uv = vim.loop

local state = {
  ---@type {[string]: string} {path: git-root}
  git = {},
}

function M.working_root()
  --- no uv.cwd() because it's not aware of tcd/cd
  return vim.fn.getcwd()
end

---@param bufnr? number
---@return string?
function M.git_root(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()

  if prefer.bo(bufnr, "buftype") ~= "" then return jelly.warn("not a regular buffer") end

  local basedir
  do
    local bufname = api.nvim_buf_get_name(bufnr)
    if bufname == "" then
      basedir = M.working_root()
    else
      if fs.is_absolute(bufname) then
        basedir = fs.parent(bufname)
      else
        basedir = fs.parent(vim.fn.fnamemodify(bufname, "%:p"))
      end
      local _, _, err = uv.fs_stat(basedir)
      if err == "ENOENT" then return jelly.warn("unable to find out basedir") end
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
