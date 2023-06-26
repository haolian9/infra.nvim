local M = {}

---@param width_percent number float(0~1)
---@param height_percent number float(0~1)
---@return number,number,number,number @width, height ,row, col
function M.editor_central(width_percent, height_percent)
  assert(width_percent < 1 and height_percent < 1)

  local cols, lines = vim.go.columns, vim.go.lines

  -- stole from plenary.window.float
  local width = math.floor(cols * width_percent)
  local height = math.floor(lines * height_percent)

  local top_row = math.floor(((lines - height) / 2) - 1)
  local left_col = math.floor((cols - width) / 2)

  return width, height, top_row, left_col
end

return M
