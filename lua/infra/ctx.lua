local M = {}

local prefer = require("infra.prefer")

---@param bufnr integer|infra.prefer.Descriptor
---@param logic fun()
function M.no_undo(bufnr, logic)
  local bo
  if type(bufnr) == "number" then
    bo = prefer.buf(bufnr)
  else
    bo = bufnr
  end
  local orig = bo.undolevels
  bo.undolevels = -1
  local ok, err = pcall(logic)
  bo.undolevels = orig
  if not ok then error(err) end
end

return M
