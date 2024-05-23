local ex = require("infra.ex")
local winsplit = require("infra.winsplit")

local api = vim.api

---@alias infra.bufopen.Mode 'inplace'|'tab'|infra.winsplit.Side

---@param mode infra.bufopen.Mode
---@param name_or_nr string|integer @bufname or bufnr
return function(mode, name_or_nr)
  --

  local bufnr
  if type(name_or_nr) == "string" then
    bufnr = vim.fn.bufnr(name_or_nr, true)
  elseif type(name_or_nr) == "number" then
    bufnr = bufnr
  else
    error(string.format("unreachable: invalid name_or_nr=%s", name_or_nr))
  end

  if mode == "inplace" then
    api.nvim_win_set_buf(0, bufnr)
  elseif mode == "tab" then
    ex.eval("tab sbuffer %d", bufnr)
  else
    ---@diagnostic disable-next-line: param-type-mismatch
    winsplit(mode, bufnr)
  end
end
