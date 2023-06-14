local M = {}

-- iterate over list.values
---@param list any[]
---@return infra.Iterator.Any
function M.iter(list)
  local cursor = 1
  return function()
    if cursor > #list then return end
    local el = list[cursor]
    cursor = cursor + 1
    return el
  end
end

---@param list any[][] list of tuple
---@return fun():...any
function M.iter_unpacked(list)
  local iter = M.iter(list)
  return function() return unpack(iter() or {}) end
end

-- inplace extend
---@param a any[]
---@param b infra.Iterable.Any
function M.extend(a, b)
  local b_type = type(b)
  if b_type == "table" then
    for el in M.iter(b) do
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

---@param stack any[]
---@return any?
function M.pop(stack)
  local len = #stack
  if len == 0 then return end
  -- idk if table.remove has such optimization
  local tail = stack[len]
  stack[len] = nil
  return tail
end

---@param stack any[]
function M.push(stack, el) table.insert(stack, 1, el) end

return M
