local M = {}

local api = vim.api

---of current or given winid
---@param winid? integer @nil=current win
---@return integer @1-based
function M.row(winid)
  winid = winid or api.nvim_get_current_win()
  return api.nvim_win_get_cursor(winid)[1]
end

---of current or given winid
---@param winid? integer @nil=current win
---@return integer @0-based
function M.lnum(winid)
  winid = winid or api.nvim_get_current_win()
  return M.row(winid) - 1
end

---of current or given winid
---@param winid? integer @nil=current win
---@return integer @0-based
function M.col(winid)
  winid = winid or api.nvim_get_current_win()
  return api.nvim_win_get_cursor(winid)[2]
end

---of current or given winid
---@param winid? integer @nil=current win
---@return {lnum: integer, col: integer, row: integer}
function M.position(winid)
  winid = winid or api.nvim_get_current_win()
  local rc = api.nvim_win_get_cursor(winid)
  return { lnum = rc[1] - 1, col = rc[2], row = rc[1] }
end

---of current or given winid
---@param winid? integer @nil=current win
---@return integer,integer @row,col
function M.rc(winid)
  winid = winid or api.nvim_get_current_win()
  return unpack(api.nvim_win_get_cursor(winid))
end

---of current or given winid
---@param winid? integer @nil=current win
---@return integer,integer @row,col
function M.lc(winid)
  winid = winid or api.nvim_get_current_win()
  local rc = api.nvim_win_get_cursor(winid)
  return rc[1] - 1, rc[2]
end

---move the cursor of current or given winid
---@param winid? integer
---@param lnum integer @0-based
---@param col integer @0-based
function M.go(winid, lnum, col)
  winid = winid or api.nvim_get_current_win()
  api.nvim_win_set_cursor(winid, { lnum + 1, col })
end

---move the cursor of current or given winid
---@param winid? integer
---@param row integer @1-based
---@param col integer @0-based
function M.g1(winid, row, col)
  winid = winid or api.nvim_get_current_win()
  api.nvim_win_set_cursor(winid, { row, col })
end

return M
