local M = {}

---movititation: (in my personal opionion)
---* no strict_indexing param
---   * nvim_buf_get/set_lines makes no sense, it'd be false here always
---   * actually strict_indexing=true had bitten me several times with no reason, i consulted the matrix nvim room and got no answer
---   * so it'd be better to just omit this param
---* intuitive, simple responsibility api
---   * nvim_buf_get/set_lines is not designed for human, with too many param combination

local fn = require("infra.fn")

local api = vim.api

do
  ---@param start_lnum integer @0-based, inclusive
  ---@param stop_lnum integer @0-based, exclusive
  ---@return string[]
  function M.lines(bufnr, start_lnum, stop_lnum)
    ---valid   forms: 1,2; -2,-1; 0,-1; 3,-2
    ---invalid forms: 2,1; -1,-2; -2,3
    if not (start_lnum >= 0 and stop_lnum < 0) then assert(stop_lnum > start_lnum, "empty range") end

    return api.nvim_buf_get_lines(bufnr, start_lnum, stop_lnum, false)
  end

  ---@param bufnr integer
  ---@param lnum integer @0-based
  ---@return string?
  function M.line(bufnr, lnum) return M.lines(bufnr, lnum, lnum + 1)[1] end

  ---@param bufnr integer
  ---@return string[]
  function M.all(bufnr) return M.lines(bufnr, 0, -1) end

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
  ---@param range fun(): integer?
  ---@return fun(): (string?,integer?) @iter(line,lnum)
  local function main(bufnr, range)
    return fn.map(function(lnum) return M.line(bufnr, lnum), lnum end, range)
  end

  ---@param bufnr integer
  ---@return fun(): string?,integer? @iter(line,lnum)
  function M.iter(bufnr) return main(bufnr, fn.range(M.count(bufnr))) end

  ---@param bufnr integer
  ---@return fun(): string?,integer? @iter(line,lnum)
  function M.iter_reversed(bufnr) return main(bufnr, fn.range(M.count(bufnr) - 1, 0 - 1, -1)) end
end

do
  ---@param bufnr integer
  ---@param pattern string @pattern for vim.regex
  ---@param negative boolean @if match given pattern
  ---@return fun(): string?,integer? @iter(line,lnum)
  local function main(bufnr, pattern, negative)
    --todo: need to cache this regex object?
    local regex = vim.regex(pattern)

    local iter = fn.range(M.count(bufnr))

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
  ---@param pattern string @pattern for vim.regex
  ---@return fun(): string?,integer? @iter(line,lnum)
  function M.iter_matched(bufnr, pattern) return main(bufnr, pattern, false) end

  ---@param bufnr integer
  ---@param pattern string @pattern for vim.regex
  ---@return fun(): string?,integer? @iter(line,lnum)
  function M.iter_unmatched(bufnr, pattern) return main(bufnr, pattern, true) end
end

do
  ---@param bufnr integer
  ---@param lnum integer @0-based
  ---@param start_col integer @0-based, inclusive
  ---@param stop_col integer @0-based, exclusive
  ---@return string?
  function M.text(bufnr, lnum, start_col, stop_col)
    local lines = api.nvim_buf_get_text(bufnr, lnum, start_col, lnum, stop_col, {})
    assert(#lines <= 1)
    return lines[1]
  end
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
