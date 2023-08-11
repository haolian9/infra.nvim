local M = {}

local jelly = require("infra.jellyfish")("infra.dictlib")

---@alias Dict {[any]: any}

---NB: no order guarantee
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
    assert(type(layer) == "table", path)
    layer = layer[path]
    if layer == nil then return end
  end
  return layer
end

---@param cap integer
---@param weakable_value? boolean @nil=false
---@return Dict
function M.CappedDict(cap, weakable_value)
  if weakable_value == nil then weakable_value = false end

  local remain = cap

  ---'k' makes no sense, since keys are string always in my use
  local mode = weakable_value and "v" or nil

  ---wrorkaround to maintain a reasonable 'remain' value, as get() and set() always apear in pairs
  local index = weakable_value and function() remain = remain + 1 end or nil

  return setmetatable({}, {
    __mode = mode,
    __index = index,
    __newindex = function(t, k, v)
      local exists = rawget(t, k) ~= nil
      if exists then
        rawset(t, k, v)
        if v == nil then remain = remain + 1 end
      else
        if remain == 0 then
          jelly.err("keys: %s", table.concat(M.keys(t), " "))
          error("full", cap)
        end
        rawset(t, k, v)
        if v ~= nil then remain = remain - 1 end
      end
    end,
  })
end

return M
