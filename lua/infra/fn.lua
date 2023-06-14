local M = {}

local listlib = require("infra.listlib")

---@alias infra.Iterator.Any fun(): any?
---@alias infra.Iterable.Any infra.Iterator.Any|any[]
--
---@alias infra.Iterator.Str fun(): string?
---@alias infra.Iterable.Str infra.Iterator.Str|string[]

-- parts can be empty string
---@param str string
---@param del string
---@param maxsplit number? @specified or infinited
---@param keepends boolean? @specified or false
---@return infra.Iterator.Str
function M.split_iter(str, del, maxsplit, keepends)
  keepends = keepends or false

  local pattern = del
  if del == "." then
    pattern = "%."
  elseif del == "%" then
    pattern = "%%"
  end

  local finished = false
  local cursor = 1
  local remain = (maxsplit or math.huge) + 1

  return function()
    if finished then return end

    if remain == 1 then
      finished = true
      return str:sub(cursor)
    end

    local del_start, del_stop = str:find(pattern, cursor)
    if del_start == nil then
      finished = true
      return str:sub(cursor)
    end

    remain = remain - 1
    local start = cursor
    local stop = del_start - 1
    if keepends then stop = del_stop end
    cursor = del_stop + 1
    return str:sub(start, stop)
  end
end

-- parts can be empty string
---@return string[]
function M.split(str, del, maxsplit, keepends) return M.concrete(M.split_iter(str, del, maxsplit, keepends)) end

---@param iterable infra.Iterable.Str
---@param del ?string @specified or ""
---@return string
function M.join(iterable, del)
  del = del or ""
  local list
  do
    local iter_type = type(iterable)
    if iter_type == "function" then
      list = M.concrete(iterable)
    elseif iter_type == "table" then
      list = iterable
    else
      error("unexpected type: " .. iter_type)
    end
  end
  return table.concat(list, del)
end

---@param iterable function|table @iterator or list
---@return infra.Iterator.Any
function M.iter(iterable)
  local iter_type = type(iterable)
  if iter_type == "function" then
    return iterable
  elseif iter_type == "table" then
    return listlib.iter(iterable)
  else
    error("unknown type of iter: " .. iter_type)
  end
end

---@param iterable infra.Iterable.Any
---@param size number
---@return fun(): any[]?
function M.batch(iterable, size)
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

---@param it infra.Iterable.Any
---@return any[]
function M.concrete(it)
  local list = {}
  for el in it do
    table.insert(list, el)
  end
  return list
end

---@param fn fun(el: any): any
---@param iterable infra.Iterable.Any
---@return infra.Iterator.Any
function M.map(fn, iterable)
  local it = M.iter(iterable)

  return function()
    local el = { it() }
    if #el == 0 then return end
    return fn(unpack(el))
  end
end

function M.walk(fn, iterable)
  local it = M.iter(iterable)
  while true do
    -- todo: optimize when 'it' only returns one value
    local el = { it() }
    if #el == 0 then break end
    fn(unpack(el))
  end
end

-- zip.length == longest.length
-- due to lua's for treats first nil as terminate of one iterable
-- todo: support varargs
--
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

---@param a infra.Iterable.Any
---@param b infra.Iterable.Any
---@return boolean
function M.iter_equals(a, b)
  for ziped in M.zip_longest(a, b) do
    if ziped[1] ~= ziped[2] then return false end
  end
  return true
end

do
  local function evaluate(thing)
    if type(thing) == "function" then return thing() end
    return thing
  end

  function M.either(truthy, a, b)
    if evaluate(truthy) then return evaluate(a) end
    return evaluate(b)
  end
end

function M.nilor(a, b)
  if a ~= nil then return a end
  return b
end

---@param iterable fun():infra.Iterable.Any
---@return infra.Iterator.Any
function M.iter_chained(iterable)
  local it = nil
  return function()
    while true do
      if it == nil then
        local maybe_it = iterable()
        if maybe_it == nil then return end
        it = M.iter(maybe_it)
      end
      local el = it()
      if el ~= nil then return el end
      it = nil
    end
  end
end

---@param ... infra.Iterable.Any
---@return infra.Iterator.Any
function M.chained(...) return M.iter_chained(M.map(M.iter, { ... })) end

---@param fn fun(...): boolean
---@return infra.Iterable.Any
function M.filter(fn, iterable)
  local it = M.iter(iterable)
  return function()
    while true do
      local el = { it() }
      if #el == 0 then return end
      if fn(unpack(el)) then return unpack(el) end
    end
  end
end

---@param iterable infra.Iterable.Any
---@param needle any
---@return boolean
function M.contains(iterable, needle)
  for el in M.iter(iterable) do
    if el == needle then return true end
  end
  return false
end

-- when iterable's each stop takes time, fastforward would block for a certain time
-- inclusive start, inclusive stop
---@param iterable infra.Iterable.Any
---@param start number
---@param stop number
---@return infra.Iterator.Any
function M.slice(iterable, start, stop)
  assert(start > 0 and stop >= start)

  local it = M.iter(iterable)

  for _ = 1, start - 1 do
    assert(it())
  end

  local remain = stop + 1 - start
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

-- same as python's range: inclusive start, exclusive stop
---@param start number
---@param stop number?
---@param step number?
---@return infra.Iterator.Any
function M.range(start, stop, step)
  if stop == nil then
    stop = start
    start = 0
  end
  assert(stop >= start)
  step = step or 1
  assert(step > 0)

  local cursor = start - step
  return function()
    cursor = cursor + step
    if stop <= cursor then return end
    return cursor
  end
end

---@param iterable infra.Iterable.Any
---@return {[any]: true}
function M.toset(iterable)
  local set = {}
  for k in M.iter(iterable) do
    set[k] = true
  end
  return set
end

return M
