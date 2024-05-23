local M = {}

local ropes = require("string.buffer")

---@alias infra.Iterator.Any fun(): ...
---@alias infra.Iterable.Any infra.Iterator.Any|any[]
--
---@alias infra.Iterator.Str fun(): string?
---@alias infra.Iterable.Str infra.Iterator.Str|string[]
--
---@alias infra.Iterator.Int fun(): integer?
---@alias infra.Iterable.Str infra.Iterator.Int|integer[]

---forms:
---* (3)
---* (0, 3)
---* (0, 3, 1)
---* (3, 0, -1)
---@param from integer @inclusive
---@param to? integer @exclusive, nil=0
---@param step? integer @nil=1
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

---@param iterable function|table @iterator or list
---@return infra.Iterator.Any
function M.iter(iterable)
  local iter_type = type(iterable)
  if iter_type == "function" then
    return iterable
  elseif iter_type == "table" then
    local cursor = 1
    return function()
      if cursor > #iterable then return end
      local el = iterable[cursor]
      cursor = cursor + 1
      return el
    end
  else
    error("unknown type of iter: " .. iter_type)
  end
end

---@param iterable infra.Iterable.Any
---@param size number
---@return fun(): any[]?
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

---@param fn fun(el: any): ...
---@param iterable infra.Iterable.Any
---@return infra.Iterator.Any
function M.map(fn, iterable)
  local it = M.iter(iterable)

  return function()
    local el = it()
    if el == nil then return end
    return fn(el)
  end
end

---for iters which return more than one value in each iteration
---@param fn fun(el: any): ...
---@param iterable infra.Iterable.Any
---@return infra.Iterator.Any
function M.mapn(fn, iterable)
  local it = M.iter(iterable)

  return function()
    local el = { it() }
    if #el == 0 then return end
    return fn(unpack(el))
  end
end

---NB: the el[key] is not supposed to be nil
---@param iterable table[]|fun(): table[]?
---@param key string|integer
---@return fun(): any[]?
function M.project(iterable, key)
  local it = M.iter(iterable)

  return function()
    local el = it()
    if el == nil then return end
    ---todo: what if el.key is nil?
    return assert(el[key])
  end
end

---@param predicate fun(el: any): boolean
---@return infra.Iterator.Any
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
---@param predicate fun(...): boolean
---@param iterable infra.Iterable.Any
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

-- zip.length == longest.length
-- due to lua's for treats first nil as terminate of one iterable
---@param a infra.Iterable.Any
---@param b infra.Iterable.Any
---@return fun(): any[]?
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

-- zip.length == shortest.length
---@param a infra.Iterable.Any
---@param b infra.Iterable.Any
---@return fun(): any[]?
function M.zip(a, b)
  local it = M.zip_longest(a, b)
  return function()
    for ziped in it do
      if ziped[1] == nil or ziped[2] == nil then return end
      return ziped
    end
  end
end

---@param ... infra.Iterable.Any
---@return infra.Iterator.Any
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
      if el == nil then it = nil end
      return el
    end
  end
end

---flatten fun(): nil|(fun(): nil|any)|any[]
---@param iterable infra.Iterable.Any
function M.flatten(iterable)
  local child

  return function()
    while true do
      if child == nil then
        child = iterable()
        if child == nil then return end
        child = M.iter(child)
      end
      local el = child()
      if el == nil then child = nil end
      return el
    end
  end
end

-- when iterable's each step takes time, fastforward would block for a certain time
---@param iterable infra.Iterable.Any
---@param start integer @1-based, inclusive
---@param stop integer @1-based, exclusive
---@return infra.Iterator.Any
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
  ---@param iterable infra.Iterable.Any
  ---@param needle any
  ---@return boolean
  function M.contains(iterable, needle)
    for el in M.iter(iterable) do
      if el == needle then return true end
    end
    return false
  end

  ---@param a infra.Iterable.Any
  ---@param b infra.Iterable.Any
  ---@return boolean
  function M.equals(a, b)
    for ziped in M.zip_longest(a, b) do
      if ziped[1] ~= ziped[2] then return false end
    end
    return true
  end

  ---@param iterable infra.Iterator.Int
  ---@return integer?
  function M.max(iterable)
    local iter = M.iter(iterable)

    local val

    val = iter()
    if val == nil then return end

    for el in iter do
      if val < el then val = el end
    end

    return val
  end

  ---@param iterable infra.Iterator.Int
  ---@return integer?
  function M.min(iterable)
    local iter = M.iter(iterable)

    local val

    val = iter()
    if val == nil then return end

    for el in iter do
      if val > el then val = el end
    end

    return val
  end

  ---@param iterable infra.Iterable.Str
  ---@param separator ?string @specified or ""
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

  ---@param fn fun(el)
  ---@param iterable infra.Iterator.Any
  function M.foreach(fn, iterable)
    for el in M.iter(iterable) do
      fn(el)
    end
  end

  ---@param fn fun(...)
  ---@param iterable infra.Iterator.Any
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
  ---@param iterable infra.Iterable.Any
  ---@return any[]
  function M.tolist(iterable)
    if type(iterable) == "table" then return iterable end

    local list = {}
    for el in iterable do
      table.insert(list, el)
    end
    return list
  end

  ---NB: no order guarantee
  ---@param iterable infra.Iterable.Any
  ---@return {[any]: true}
  function M.toset(iterable)
    local set = {}
    for k in M.iter(iterable) do
      set[k] = true
    end
    return set
  end

  ---@param kv fun(): string|number,any
  ---@return {[string|number]: any}
  function M.todict(kv)
    local dict = {}
    for k, v in kv do
      dict[k] = v
    end
    return dict
  end
end

return M
