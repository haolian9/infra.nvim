local M = {}

---@generic T
---@param impl T
---@return T
function M.dotize(impl)
  return setmetatable({}, {
    __index = function(t, key)
      local f = function(...) return impl[key](impl, ...) end
      rawset(t, key, f)
      return f
    end,
  })
end

return M
