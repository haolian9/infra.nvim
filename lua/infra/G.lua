---@param ns string @namespace: a plugin name
---@return table
return function(ns)
  if _G.g == nil then _G.g = {} end
  if _G.g[ns] == nil then _G.g[ns] = {} end
  return _G.g[ns]
end
