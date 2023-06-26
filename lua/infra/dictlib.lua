local M = {}

---@alias Dict {[any]: any}

---@param dict Dict
---@return any[]
function M.keys(dict)
  local keys = {}
  for key, _ in pairs(dict) do
    table.insert(keys, key)
  end
  return keys
end

---@param dreams Dict
---@param ... string|number trace
function M.get(dreams, ...)
  local layer = dreams
  for _, path in ipairs({ ... }) do
    assert(type(layer) == "table")
    layer = layer[path]
    if layer == nil then return end
  end
  return layer
end

---@param cap integer
---@return Dict
function M.CappedDict(cap)
  local remain = cap
  return setmetatable({}, {
    __newindex = function(t, k, v)
      if remain == 0 then error("full") end
      rawset(t, k, v)
      if v == nil then
        remain = remain + 1
      else
        remain = remain - 1
      end
    end,
  })
end

return M
