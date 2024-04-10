local M = {}

local fn = require("infra.fn")

local api = vim.api

do
  ---@param bufnr integer
  ---@param range fun(): integer?
  ---@return fun(): string?,integer? @iter(line,lnum)
  local function main(bufnr, range)
    return fn.map(function(lnum)
      local line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
      ---@diagnostic disable-next-line: redundant-return-value
      return line, lnum
    end, range)
  end

  ---@param bufnr integer
  ---@return fun(): string?,integer? @iter(line,lnum)
  function M.iter(bufnr) return main(bufnr, fn.range(api.nvim_buf_line_count(bufnr))) end

  ---@param bufnr integer
  ---@return fun(): string?,integer? @iter(line,lnum)
  function M.reversed(bufnr) return main(bufnr, fn.range(api.nvim_buf_line_count(bufnr) - 1, 0 - 1, -1)) end
end

do
  ---@param bufnr integer
  ---@param pattern string @pattern for vim.regex
  ---@param negative boolean @if match given pattern
  ---@return fun(): string?,integer? @iter(line,lnum)
  local function main(bufnr, pattern, negative)
    --todo: need to cache this regex object?
    local regex = vim.regex(pattern)

    local iter = fn.range(api.nvim_buf_line_count(bufnr))

    if negative then
      iter = fn.filter(function(lnum) return regex:match_line(bufnr, lnum) == nil end, iter)
    else
      iter = fn.filter(function(lnum) return regex:match_line(bufnr, lnum) ~= nil end, iter)
    end

    iter = fn.map(function(lnum)
      local line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
      ---@diagnostic disable-next-line: redundant-return-value
      return line, lnum
    end, iter)

    return iter
  end

  ---@param bufnr integer
  ---@param pattern string @pattern for vim.regex
  ---@return fun(): string?,integer? @iter(line,lnum)
  function M.matched(bufnr, pattern) return main(bufnr, pattern, false) end

  ---@param bufnr integer
  ---@param pattern string @pattern for vim.regex
  ---@return fun(): string?,integer? @iter(line,lnum)
  function M.unmatched(bufnr, pattern) return main(bufnr, pattern, true) end
end

return M
