---provides project-related specs
local M = {}

local bufpath = require("infra.bufpath")
local dictlib = require("infra.dictlib")
local jelly = require("infra.jellyfish")("infra.project")
local prefer = require("infra.prefer")
local subprocess = require("infra.subprocess")

local api = vim.api

---@return string
function M.working_root()
  --- no uv.cwd() because it's not aware of tcd/cd
  return vim.fn.getcwd()
end

do
  ---@type {[string]: string|false} {path: git-root}
  local cache = dictlib.CappedDict(64)

  ---@param bufnr? number
  ---@return string?
  function M.git_root(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()

    local basedir = bufpath.dir(bufnr, true)
    if basedir == nil then return end

    local root
    local held = cache[basedir]
    if held == nil then
      local result = subprocess.run("git", { args = { "rev-parse", "--show-toplevel" }, cwd = basedir }, true)
      if result.exit_code ~= 0 then
        root = nil
        cache[basedir] = false
      else
        root = result.stdout()
        assert(root ~= nil and root ~= "")
        cache[basedir] = root
      end
    elseif held == false then
      root = nil
    else
      root = held
    end

    return root
  end
end

return M
