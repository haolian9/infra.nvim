---benefits
---* readibility: left -> right
---* shorter/concise

local itertools = require("infra.itertools")

---@class infra.its.Iterator
---@field private source fun():...
local It = {}

---@private
It.__index = It

---@private
function It:__call() return self.source() end

---@param fn? fun(el): ...
function It:map(fn)
  if fn == nil then return self end
  self.source = itertools.map(fn, self.source)
  return self
end

---@param fn? fun(...): ...
function It:mapn(fn)
  if fn == nil then return self end
  self.source = itertools.mapn(fn, self.source)
  return self
end

---NB: the el[key] is supposed to be not nil
---@param key? string|integer @key or index
function It:project(key)
  if key == nil then return self end
  self.source = itertools.project(key, self.source)
  return self
end

---@param predicate? fun(el):boolean
function It:filter(predicate)
  if predicate == nil then return self end
  self.source = itertools.filter(predicate, self.source)
  return self
end

---nargs, pass in predicate, out from filtern
---@param predicate fun(...):boolean
function It:filtern(predicate)
  if predicate == nil then return self end
  self.source = itertools.filtern(predicate, self.source)
  return self
end

---@param start integer @1-based, inclusive
---@param stop integer @1-based, exclusive
function It:slice(start, stop)
  self.source = itertools.slice(self.source, start, stop)
  return self
end

function It:flat()
  self.source = itertools.flat(self.source)
  return self
end

function It:chained(...)
  self.source = itertools.chained(self.source, ...)
  return self
end

do --the end
  ---@param needle any
  function It:contains(needle) return itertools.contains(self.source, needle) end

  ---@param gt? fun(a,b):boolean @if a>b
  function It:max(gt) return itertools.max(self.source, gt) end

  ---@param lt? fun(a,b):boolean @if a<b
  function It:min(lt) return itertools.min(self.source, lt) end

  ---@param separator ?string @nil=""
  function It:join(separator) return itertools.join(self.source, separator) end

  ---@param fn fun(el)
  function It:foreach(fn) itertools.foreach(fn, self.source) end

  ---@param fn fun(...)
  function It:foreach(fn) itertools.foreachn(fn, self.source) end

  ---@param size integer
  function It:batched(size) return itertools.batched(self.source, size) end

  function It:tolist() return itertools.tolist(self.source) end
  function It:toset() return itertools.toset(self.source) end
  function It:todict() return itertools.todict(self.source) end
  function It:tolistoftuple() return itertools.tolistoftuple(self.source) end
end

function It:unwrap() return self.source end

--todo: support operations on multiple iterators
--* zip, zip_longest
--* equals

---@param iterable any[]|fun(...):...
---@return infra.its.Iterator
return function(iterable) return setmetatable({ source = itertools.iter(iterable) }, It) end
