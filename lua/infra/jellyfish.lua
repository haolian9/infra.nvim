---for notification
---
---NB:
---* err or critical or fatal in here should not raise an error
---* each method should return nil

local strlib = require("infra.strlib")

local api = vim.api
local ll = vim.log.levels

---should not raise errors manually in any level
---@type fun(msg: string, level: integer, opts: {source: string}): nil
local provider
if true then
  function provider(msg, level, opts)
    assert(opts.source ~= nil)
    local bold, normal, dim, red = "StatusLineBufStatus", "Normal", "StatusLineAltFile", "StatusLineFilePath"
    if level <= ll.DEBUG then
      api.nvim_echo({ { opts.source, bold }, { " ", normal }, { msg, dim } }, false, {})
    elseif level < ll.WARN then
      api.nvim_echo({ { opts.source, bold }, { " ", normal }, { msg, normal } }, true, {})
    else
      api.nvim_echo({ { opts.source, bold }, { " ", normal }, { msg, red } }, true, {})
    end
  end
else
  function provider(msg, level, opts)
    assert(opts.source ~= nil)
    local meth
    if level <= ll.DEBUG then
      meth = "low"
    elseif level < ll.WARN then
      meth = "normal"
    else
      meth = "critical"
    end
    require("cthulhu").notify[meth](opts.source, msg)
  end
end

---@param source string @who sent this message
---@return fun(format: string, ...: any)
local function notify(source, level, min_level)
  assert(source and level and min_level)
  if level < min_level then return function() end end

  return function(format, ...)
    local opts = { source = source }
    if select("#", ...) ~= 0 then return provider(string.format(format, ...), level, opts) end
    assert(format ~= nil, "missing format")
    if strlib.find(format, "%s") == nil then return provider(format, level, opts) end
    error("unmatched args for format")
  end
end

---@param source string
---@param min_level number? @vim.log.levels.*; default=INFO
return function(source, min_level)
  assert(source ~= nil)
  min_level = min_level or ll.INFO

  return {
    debug = notify(source, ll.DEBUG, min_level),
    info = notify(source, ll.INFO, min_level),
    warn = notify(source, ll.WARN, min_level),
    err = notify(source, ll.ERROR, min_level),
  }
end
