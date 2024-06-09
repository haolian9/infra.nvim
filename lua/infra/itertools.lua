local M = {}

local ropes = require("string.buffer")

---forms:
---* (3)
---* (0, 3)
---* (0, 3, 1)
---* (3, 0, -1)
---@param from integer @inclusive
---@param to? integer @exclusive, nil=0
---@param step? integer @nil=1
---@return fun():integer?
function M.range(from, to, step)
  assert(step ~= 0)

  if to == nil then
    assert(step == nil)
    from, to, step = 0, from, 1
  end

  if step == nil then step = 1 end

  if step > 0 then --asc
    local cursor = from - step
    return function()
      cursor = cursor + step
      if cursor >= to then return end
      return cursor
    end
  else --desc
    local cursor = from - step
    return function()
      cursor = cursor + step
      if cursor <= to then return end
      return cursor
    end
  end
end

---@generic T
---@param iterable fun():T?|T[] @iterator or list
---@return fun(): T?
function M.iter(iterable)
  local iter_type = type(iterable)

  if iter_type == "function" then return iterable end

  if iter_type == "table" then
    local cursor = 1
    return function()
      if cursor > #iterable then return end
      local el = iterable[cursor]
      cursor = cursor + 1
      return el
    end
  end

  error("unknown type of iter: " .. iter_type)
end

---nargs out from itern
---@param iterable any[][]|fun():(any[]|nil) @list of tuple
---@return fun():...
function M.itern(iterable)
  local iter = M.iter(iterable)
  return function() return unpack(iter() or {}) end
end

---@generic T
---@param iterable fun():T?|T[]
---@param size integer
---@return fun(): T[]|?
function M.batched(iterable, size)
  local it = M.iter(iterable)
  return function()
    local stash = {}
    for el in it do
      table.insert(stash, el)
      if #stash >= size then break end
    end
    if #stash > 0 then return stash end
  end
end

---@generic T
---@param fn fun(el: T):...
---@param iterable T[]|fun():T?
---@return fun():...
function M.map(fn, iterable)
  local it = M.iter(iterable)

  return function()
    local el = it()
    if el == nil then return end
    return fn(el)
  end
end

---for iters which return more than one value in each iteration
---@param fn fun(...):...
---@param iterable fun():...
---@return fun():...
function M.mapn(fn, iterable)
  local it = M.iter(iterable)

  return function()
    local el = { it() }
    if #el == 0 then return end
    return fn(unpack(el))
  end
end

---NB: the el[key] is supposed to be not nil
---@param key string|integer @key or index
---@param iterable table[]|fun():table[]?
---@return fun(): any[]?
function M.project(key, iterable)
  local it = M.iter(iterable)

  return function()
    local el = it()
    if el == nil then return end
    return assert(el[key])
  end
end

---@generic T
---@param predicate fun(el):boolean
---@param iterable T[]|fun():T?
---@return fun():T?
function M.filter(predicate, iterable)
  local it = M.iter(iterable)
  return function()
    while true do
      local el = it()
      if el == nil then return end
      if predicate(el) then return el end
    end
  end
end

---nargs, pass in predicate, out from filtern
---@param predicate fun(...):boolean
---@param iterable fun(...):...
---@return fun():...
function M.filtern(predicate, iterable)
  local it = M.iter(iterable)
  return function()
    while true do
      local el = { it() }
      if #el == 0 then return end
      if predicate(unpack(el)) then return unpack(el) end
    end
  end
end

---zip.length == longest.length
-- due to lua's for treats first nil as terminate of one iterable
---@generic T
---@generic T2
---@param a T[]|fun():T?
---@param b T2[]|fun():T2?
---@return fun():[T,T2]?
function M.zip_longest(a, b)
  local ai = M.iter(a)
  local bi = M.iter(b)
  return function()
    local ae = ai()
    local be = bi()
    if ae == nil and be == nil then return end
    return { ae, be }
  end
end

---zip.length == shortest.length
---@generic T
---@generic T2
---@param a T[]|fun():T?
---@param b T2[]|fun():T2?
---@return fun(): [T,T2]?
function M.zip(a, b)
  local it = M.zip_longest(a, b)
  return function()
    for ziped in it do
      if ziped[1] == nil or ziped[2] == nil then return end
      return ziped
    end
  end
end

---@generic T
---@param ... T[]|fun():T?
---@return fun():T?
function M.chained(...)
  local it = nil
  local arg_it = M.iter({ ... })

  return function()
    while true do
      if it == nil then
        local maybe_it = arg_it()
        if maybe_it == nil then return end
        it = M.iter(maybe_it)
      end
      local el = it()
      if el ~= nil then return el end
      it = nil
    end
  end
end

---@generic T
---@param iters fun():(T[]|fun():T?|nil)
---@return fun():T?
function M.flat(iters)
  local iter

  return function()
    while true do
      if iter == nil then
        iter = iters()
        if iter == nil then return end
        iter = M.iter(iter)
      end
      local el = iter()
      if el ~= nil then return el end
      iter = nil
    end
  end
end

-- when iterable's each step takes time, fastforward would block for a certain time
---@generic T
---@param iterable T[]|fun():T?
---@param start integer @1-based, inclusive
---@param stop integer @1-based, exclusive
---@return fun():T?
function M.slice(iterable, start, stop)
  assert(start > 0 and stop > start)

  local it = M.iter(iterable)

  for _ = 1, start - 1 do
    assert(it())
  end

  local remain = stop - start
  return function()
    if remain < 1 then return end
    local el = { it() }
    if #el == 0 then
      remain = 0
    else
      remain = remain - 1
    end
    return unpack(el)
  end
end

do --reduce/consume/drain
  ---@generic T
  ---@param iterable T[]|fun():T?
  ---@param needle T
  ---@return boolean
  function M.contains(iterable, needle)
    for el in M.iter(iterable) do
      if el == needle then return true end
    end
    return false
  end

  ---@generic T
  ---@param a T[]|fun():T?
  ---@param b T[]|fun():T?
  ---@return boolean
  function M.equals(a, b)
    for ziped in M.zip_longest(a, b) do
      if ziped[1] ~= ziped[2] then return false end
    end
    return true
  end

  ---@generic T
  ---@param iterable T[]|fun():T?
  ---@param gt? fun(a:T,b:T):boolean @if a>b
  ---@return T?
  function M.max(iterable, gt)
    local iter = M.iter(iterable)
    if gt == nil then gt = function(a, b) return a > b end end

    local max

    max = iter()
    if max == nil then return end

    for el in iter do
      if gt(el, max) then max = el end
    end

    return max
  end

  ---@generic T
  ---@param iterable T[]|fun():T?
  ---@param lt? fun(a:T,b:T):boolean @if a<b
  ---@return T?
  function M.min(iterable, lt)
    local iter = M.iter(iterable)
    if lt == nil then lt = function(a, b) return a < b end end

    local min

    min = iter()
    if min == nil then return end

    for el in iter do
      if lt(el, min) then min = el end
    end

    return min
  end

  ---@param iterable string[]|fun():string?
  ---@param separator ?string @nil=""
  ---@return string
  function M.join(iterable, separator)
    separator = separator or ""

    local rope = ropes.new()
    for el in M.iter(iterable) do
      rope:put(separator, el)
    end
    rope:skip(#separator)

    return rope:get()
  end

  ---@generic T
  ---@param fn fun(el: T)
  ---@param iterable T[]|fun():T?
  function M.foreach(fn, iterable)
    for el in M.iter(iterable) do
      fn(el)
    end
  end

  ---@param fn fun(...)
  ---@param iterable fun():...
  function M.foreachn(fn, iterable)
    local it = M.iter(iterable)

    while true do
      local el = { it() }
      if #el == 0 then break end
      fn(unpack(el))
    end
  end
end

do
  ---@generic T
  ---@param iterable T[]|fun():T?
  ---@return T[]
  function M.tolist(iterable)
    if type(iterable) == "table" then return iterable end

    local list = {}
    for el in iterable do
      table.insert(list, el)
    end
    return list
  end

  ---NB: no order guarantee
  ---@generic T
  ---@param iterable T[]|fun():T?
  ---@return {[T]: true}
  function M.toset(iterable)
    local set = {}
    for k in M.iter(iterable) do
      set[k] = true
    end
    return set
  end

  ---@generic K
  ---@generic V
  ---@param kv fun():K?,V?
  ---@return {[K]: V}
  function M.todict(kv)
    local dict = {}
    for k, v in kv do
      dict[k] = v
    end
    return dict
  end

  ---@param iter fun():...
  function M.tolistoftuple(iter)
    local list = {}
    while true do
      local el = { iter() }
      if #el == 0 then break end
      table.insert(list, el)
    end
    return list
  end
end

return M
