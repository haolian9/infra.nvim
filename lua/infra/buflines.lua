local M = {}

---movititation: (in my personal opionion)
---* no strict_indexing param
---   * nvim_buf_get/set_lines makes no sense, it'd be false here always
---   * actually strict_indexing=true had bitten me several times with no reason, i consulted the matrix nvim room and got no answer
---   * so it'd be better to just omit this param
---* intuitive, simple responsibility api
---   * nvim_buf_get/set_lines is not designed for human, with too many param combination

local fn = require("infra.fn")
local jelly = require("infra.jellyfish")("infra.buflines", "debug")
local unsafe = require("infra.unsafe")

local ropes = require("string.buffer")

local api = vim.api

---notes:
---* -1=high
---* start is inclusive
---* stop is exclusive
---@param bufnr integer
---@param start? integer @0-based, inclusive
---@param stop? integer @0-based, exclusive
---@return integer,integer @start,stop
local function resolve_range(bufnr, start, stop)
  local high = M.high(bufnr)

  --todo: if step=-1, start should not start with 0

  if start == nil and stop == nil then return 0, high + 1 end

  if start ~= nil and stop == nil then
    if start >= 0 then return 0, start end
    stop = high + (start + 1)
    assert(stop >= 0, "invalid stop value")
    return 0, stop
  end

  do
    assert(start and stop)
    if start < 0 then start = high + (start + 1) end
    assert(start >= 0, "illegal start value")
    if stop < 0 then stop = high + (stop + 1) end
    assert(stop >= 0, "illegal stop value")

    return start, stop
  end
end

do
  ---@param bufnr integer
  ---@return integer
  function M.count(bufnr) return api.nvim_buf_line_count(bufnr) end

  ---@param bufnr integer
  ---@return integer @>=0
  function M.high(bufnr)
    local count = M.count(bufnr) - 1
    return math.max(0, count)
  end
end

do
  ---@param bufnr integer
  ---@param start_lnum? integer @0-based, inclusive
  ---@param stop_lnum? integer @0-based, exclusive
  ---@return string[]
  function M.lines(bufnr, start_lnum, stop_lnum)
    start_lnum, stop_lnum = resolve_range(bufnr, start_lnum, stop_lnum)

    return api.nvim_buf_get_lines(bufnr, start_lnum, stop_lnum, false)
  end

  ---@param bufnr integer
  ---@param lnum integer @0-based, accepts -1
  ---@return string?
  function M.line(bufnr, lnum)
    if lnum == -1 then lnum = M.high(bufnr) end
    return M.lines(bufnr, lnum, lnum + 1)[1]
  end
end

do
  ---@param bufnr integer
  ---@param start_lnum? integer @0-based, inclusive
  ---@param stop_lnum? integer @0-based, exclusive
  ---@return string
  function M.joined(bufnr, start_lnum, stop_lnum)
    local range = fn.range(resolve_range(bufnr, start_lnum, stop_lnum))

    local rope = ropes.new()
    for ptr, len in unsafe.lineref_iter(bufnr, range) do
      rope:put("\n")
      rope:putcdata(ptr, len)
    end
    rope:skip(#"\n")

    return rope:get()
  end
end

do
  ---@param bufnr integer
  ---@param lnum integer @0-based
  ---@param start_col integer @0-based, inclusive
  ---@param stop_col integer @0-based, exclusive
  ---@return string?
  function M.partial_line(bufnr, lnum, start_col, stop_col)
    local lines = api.nvim_buf_get_text(bufnr, lnum, start_col, lnum, stop_col, {})
    assert(#lines <= 1)
    return lines[1]
  end
end

do
  ---@param bufnr integer
  ---@param start_lnum? integer @0-based, inclusive
  ---@param stop_lnum? integer @0-based, exclusive
  ---@return fun():string?,integer? @iter(line,lnum)
  function M.iter(bufnr, start_lnum, stop_lnum)
    local range = fn.range(resolve_range(bufnr, start_lnum, stop_lnum))
    return fn.map(function(lnum) return M.line(bufnr, lnum), lnum end, range)
  end

  ---@param bufnr integer
  ---@return fun(): string?,integer? @iter(line,lnum)
  function M.iter_reversed(bufnr)
    --todo: support start_lnum, stop_lnum
    local range = fn.range(M.high(bufnr), 0 - 1, -1)
    return fn.map(function(lnum) return M.line(bufnr, lnum), lnum end, range)
  end
end

do
  ---@param bufnr integer
  ---@param regex vim.Regex
  ---@param negative boolean
  ---@param start_lnum? integer @0-based, inclusive
  ---@param stop_lnum? integer @0-based, exclusive
  ---@return fun(): string?,integer? @iter(line,lnum)
  local function main(bufnr, regex, negative, start_lnum, stop_lnum)
    local iter

    iter = fn.range(resolve_range(bufnr, start_lnum, stop_lnum))
    if negative then
      iter = fn.filter(function(lnum) return regex:match_line(bufnr, lnum) == nil end, iter)
    else
      iter = fn.filter(function(lnum) return regex:match_line(bufnr, lnum) ~= nil end, iter)
    end
    iter = fn.map(function(lnum)
      local line = M.lines(bufnr, lnum, lnum + 1)[1]
      ---@diagnostic disable-next-line: redundant-return-value
      return line, lnum
    end, iter)

    return iter
  end

  ---@param bufnr integer
  ---@param regex vim.Regex
  ---@param start_lnum? integer @0-based, inclusive
  ---@param stop_lnum? integer @0-based, exclusive
  ---@return fun(): string?,integer? @iter(line,lnum)
  function M.iter_matched(bufnr, regex, start_lnum, stop_lnum) return main(bufnr, regex, false, start_lnum, stop_lnum) end

  ---@param bufnr integer
  ---@param regex vim.Regex
  ---@param start_lnum? integer @0-based, inclusive
  ---@param stop_lnum? integer @0-based, exclusive
  ---@return fun(): string?,integer? @iter(line,lnum)
  function M.iter_unmatched(bufnr, regex, start_lnum, stop_lnum) return main(bufnr, regex, true, start_lnum, stop_lnum) end
end

do
  ---@param bufnr integer
  ---@param start_lnum integer @0-based, inclusive
  ---@param stop_lnum integer @0-based, exclusive
  ---@param lines string[]
  function M.sets(bufnr, start_lnum, stop_lnum, lines) api.nvim_buf_set_lines(bufnr, start_lnum, stop_lnum, false, lines) end

  ---@param bufnr integer
  ---@param lnum integer @0-based, inclusive
  ---@param line string
  function M.replace(bufnr, lnum, line) M.sets(bufnr, lnum, lnum + 1, { line }) end

  ---@param bufnr integer
  ---@param start_lnum integer @0-based, inclusive, could be negative
  ---@param stop_lnum integer @0-based, exclusive, could be negative
  ---@param lines string[]
  function M.replaces(bufnr, start_lnum, stop_lnum, lines)
    assert(stop_lnum > start_lnum, "+1? stop_lnum is exclusive")
    M.sets(bufnr, start_lnum, stop_lnum, lines)
  end

  ---@param bufnr integer
  ---@param lines string[]
  function M.replaces_all(bufnr, lines) M.sets(bufnr, 0, -1, lines) end

  ---@param bufnr integer
  ---@param lnum integer @0-based, exclusive
  ---@param line string
  function M.append(bufnr, lnum, line) M.sets(bufnr, lnum + 1, lnum + 1, { line }) end

  ---@param bufnr integer
  ---@param lnum integer @0-based, exclusive
  ---@param lines string[]
  function M.appends(bufnr, lnum, lines) M.sets(bufnr, lnum + 1, lnum + 1, lines) end

  ---@param bufnr integer
  ---@param lnum integer @0-based, exclusive
  ---@param line string
  function M.prepend(bufnr, lnum, line) M.sets(bufnr, lnum, lnum, { line }) end

  ---@param bufnr integer
  ---@param lnum integer @0-based, exclusive
  ---@param lines string[]
  function M.prepends(bufnr, lnum, lines) M.sets(bufnr, lnum, lnum, lines) end
end

return M