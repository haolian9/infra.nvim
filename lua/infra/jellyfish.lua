---for notification
---
---NB:
---* err or critical or fatal in here should not raise an error
---* each method should return nil

local strfmt = require("infra._strfmt")
local strlib = require("infra.strlib")

local api = vim.api

---log level
---@type {[string|integer]: integer}
local ll = {}
for _, name in ipairs({ "DEBUG", "INFO", "WARN", "ERROR" }) do
  local val = vim.log.levels[name]
  ll[name] = val
  ll[string.lower(name)] = val
  ll[val] = val
end

---should not raise errors manually in any level
---@type fun(msg: string, level: integer, opts: {source: string}): nil
local provider
if true then
  local function nvim_schedule_echo(chunks, history, opts)
    vim.schedule(function() api.nvim_echo(chunks, history, opts) end)
  end

  function provider(msg, level, opts)
    assert(opts.source ~= nil)

    local nvim_echo = vim.in_fast_event() and nvim_schedule_echo or api.nvim_echo
    if level <= ll.DEBUG then
      nvim_echo({ { opts.source, "JellySource" }, { " " }, { msg, "JellyDebug" } }, true, {})
    elseif level < ll.WARN then
      nvim_echo({ { opts.source, "JellySource" }, { " " }, { msg, "JellyInfo" } }, true, {})
    else
      nvim_echo({ { opts.source, "JellySource" }, { " " }, { msg, "JellyError" } }, true, {})
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
    --todo: respect `:silent[!]`
    require("cthulhu").notify[meth](opts.source, msg)
  end
end

---@param source string @who sent this message
---@return fun(format: string, ...: any)
local function shock(source, level, min_level)
  assert(source and level and min_level)
  if level < min_level then return function() end end

  return function(format, ...)
    local opts = { source = source }
    if select("#", ...) == 0 then
      assert(format ~= nil, "missing format")
      if type(format) == "string" then
        if strlib.find(format, "%s") == nil then return provider(format, level, opts) end
        return provider(format, level, opts)
      else
        return provider(strfmt("%s", format), level, opts)
      end
    else
      return provider(strfmt(format, ...), level, opts)
    end
  end
end

---@param source string
---@param min_level string|integer|nil @{debug,info,warn,error}; nil=info
return function(source, min_level)
  assert(source ~= nil)
  min_level = assert(ll[min_level or "info"], "unknown log level")

  return {
    debug = shock(source, ll.debug, min_level),
    info = shock(source, ll.info, min_level),
    warn = shock(source, ll.warn, min_level),
    err = shock(source, ll.error, min_level),
  }
end
