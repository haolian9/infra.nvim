local M = {}

---@generic T
---@param list T[]
---@return fun(): integer?,T? @(index:0-based, value)
function M.enumerate(list)
  local cursor = 0
  return function()
    cursor = cursor + 1
    local el = list[cursor]
    if el == nil then return end
    return cursor - 1, el
  end
end

---@generic T
---@param list T[]
---@return fun(): integer?,T? @(index:1-based, value)
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
---@param b any[]|fun():any
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

---@generic T
---@param queue T[]
---@return T?
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

---@generic T
---@param n integer
---@param zero? T|fun(index:integer):T @nil=0
---@return T[]
function M.zeros(n, zero)
  local list = {}

  local eval
  if zero == nil then
    eval = function() return 0 end
  elseif type(zero) == "function" then
    eval = zero
  else
    eval = function() return zero end
  end

  for i = 1, n do
    list[i] = eval(i)
  end

  return list
end

return M
