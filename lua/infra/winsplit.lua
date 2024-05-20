local api = vim.api

---@alias infra.winsplit.Side 'above'|'below'|'left'|'right'

---split current window, put new window according to the 'side' param
---@param side infra.winsplit.Side
---@param name_or_nr? string|integer @bufname or bufnr
return function(side, name_or_nr)
  local winid = api.nvim_get_current_win()

  ---just split
  if name_or_nr == nil then return api.nvim_open_win(0, true, { split = side, win = winid }) end

  ---split with bufnr
  if type(name_or_nr) == "number" then return api.nvim_open_win(name_or_nr, true, { split = side, win = winid }) end

  ---split with bufname
  assert(type(name_or_nr) == "string" and name_or_nr ~= "")
  api.nvim_open_win(vim.fn.bufnr(name_or_nr, true), true, { split = side, win = winid })
end

