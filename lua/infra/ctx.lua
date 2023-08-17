local M = {}

local prefer = require("infra.prefer")

---@param bufnr integer
---@param logic fun()
function M.no_undo(bufnr, logic)
  local bo = prefer.buf(bufnr)
  local orig = bo.undolevels
  bo.undolevels = -1
  local ok, err = xpcall(logic, debug.traceback)
  bo.undolevels = orig
  if not ok then error(err) end
end

---@param bufnr integer
---@param logic fun()
function M.undoblock(bufnr, logic)
  --no need to wrap buf_set_lines with `undojoin`, as it will not close the undo block
  local bo = prefer.buf(bufnr)
  --close previous undo block
  local orig = bo.undolevels
  local ok, err = xpcall(logic, debug.traceback)
  --close this undo block
  bo.undolevels = orig
  if not ok then error(err) end
end

---@param bufnr integer
---@param logic fun()
function M.modifiable(bufnr, logic)
  local bo = prefer.buf(bufnr)
  if bo.modifiable then return logic() end
  bo.modifiable = true
  local ok, err = xpcall(logic, debug.traceback)
  bo.modifiable = false
  if not ok then error(err) end
end

return M
