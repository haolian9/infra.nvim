local M = {}

---@alias Dict {[any]: any}

---@param dict Dict
---@return any[]
function M.keys(dict)
  -- todo: returns an iterator
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

return M
