local api = vim.api

local cache = {
  store = {},
}

---@param key string
---@return any?
function cache:get(key) return self.store[key] end

function cache:set(key, val) self.store[key] = val end

-- designed usecases, otherwise please use api.nvim_cmd directly
-- * ("silent write")
-- * ("help", string.format("luaref-%s", keyword))
-- known bugs
-- * <leader>, <localleader>
---@param cmd string
---@param ... string|number
---@return string
return function(cmd, ...)
  local parsed

  if select("#", ...) > 0 then
    parsed = { cmd = cmd, args = { ... } }
  else
    parsed = cache:get(cmd)
    if parsed == nil then
      parsed = api.nvim_parse_cmd(cmd, {})
      cache:set(cmd, parsed)
    end
  end

  return api.nvim_cmd(parsed, { output = false })
end
