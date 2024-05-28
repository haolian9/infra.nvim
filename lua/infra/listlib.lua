local itertools = require("infra.itertools")
local M = {}

-- iterate over list.values
---@param list any[]
---@return infra.Iterator.Any iter
function M.iter(list)
  local cursor = 1
  return function()
    local el = list[cursor]
    if el == nil then return end
    cursor = cursor + 1
    return el
  end
end

---nargs out from itern
---@param list any[][] list of tuple
---@return fun():...any
function M.itern(list)
  local iter = M.iter(list)
  return function() return unpack(iter() or {}) end
end

---@param list any[]
---@return fun(): integer?,any @(index:0-based, value)
function M.enumerate(list)
  local cursor = 0
  return function()
    cursor = cursor + 1
    local el = list[cursor]
    if el == nil then return end
    return cursor - 1, el
  end
end

---@param list any[]
---@return fun(): integer?,any @(index:1-based, value)
function M.enumerate1(list)
  local cursor = 0
  return function()
    cursor = cursor + 1
    local el = list[cursor]
    if el == nil then return end
    return cursor, el
  end
end

-- inplace extend
---@param a any[]
---@param b infra.Iterable.Any
function M.extend(a, b)
  local b_type = type(b)
  if b_type == "table" then
    for _, el in ipairs(b) do
      table.insert(a, el)
    end
  elseif b_type == "function" then
    for el in b do
      table.insert(a, el)
    end
  else
    error("unsupported type of b: " .. b_type)
  end
end

---@param queue any[]
---@return any?
function M.pop(queue)
  local len = #queue
  if len == 0 then return end
  -- idk if table.remove has such optimization
  local tail = queue[len]
  queue[len] = nil
  return tail
end

---@param queue any[]
function M.push(queue, el) table.insert(queue, 1, el) end

return M
