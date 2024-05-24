local M = {}

local ex = require("infra.ex")
local winsplit = require("infra.winsplit")

local api = vim.api

---@alias infra.bufopen.Mode 'inplace'|'tab'|infra.winsplit.Side

---@param name_or_nr string|integer @bufname or bufnr
---@return integer bufnr
local function resolve_bufnr(name_or_nr)
  if type(name_or_nr) == "string" then
    return vim.fn.bufnr(name_or_nr, true)
  elseif type(name_or_nr) == "number" then
    return name_or_nr
  else
    error(string.format("unreachable: invalid name_or_nr=%s", name_or_nr))
  end
end

---@param name_or_nr string|integer @bufname or bufnr
function M.inplace(name_or_nr) api.nvim_win_set_buf(0, resolve_bufnr(name_or_nr)) end

---@param name_or_nr string|integer @bufname or bufnr
function M.tab(name_or_nr) ex.eval("tab sbuffer %d", resolve_bufnr(name_or_nr)) end

---@param name_or_nr string|integer @bufname or bufnr
function M.above(name_or_nr) winsplit("above", resolve_bufnr(name_or_nr)) end

---@param name_or_nr string|integer @bufname or bufnr
function M.below(name_or_nr) winsplit("below", resolve_bufnr(name_or_nr)) end

---@param name_or_nr string|integer @bufname or bufnr
function M.left(name_or_nr) winsplit("left", resolve_bufnr(name_or_nr)) end

---@param name_or_nr string|integer @bufname or bufnr
function M.right(name_or_nr) winsplit("right", resolve_bufnr(name_or_nr)) end

return setmetatable(M, {
  ---@param mode infra.bufopen.Mode
  ---@param name_or_nr string|integer @bufname or bufnr
  __call = function(_, mode, name_or_nr) assert(M[mode])(resolve_bufnr(name_or_nr)) end,
})
