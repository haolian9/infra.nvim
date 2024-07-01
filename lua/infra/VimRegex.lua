---@class infra.VimGrep
---@field private impl vim.Regex
local VimGrep = {}
VimGrep.__index = VimGrep

---0-based; start inclusive, stop exclusive
---@alias infra.VimGrep.Iterator fun():(start_col:integer?,stop_col:integer?)

---@param str string
---@return infra.VimGrep.Iterator
function VimGrep:iter_str(str)
  local remain = str
  local offset = 0
  return function()
    ---0-based; start inclusive, stop inclusive
    local rel_start, rel_stop = self.impl:match_str(remain)
    if not (rel_start and rel_stop) then return end

    --str.sub uses 1-based index
    remain = string.sub(remain, rel_stop + 1)

    local start, stop = rel_start + offset, rel_stop + offset
    offset = offset + rel_stop

    return start, stop
  end
end

---@param bufnr integer
---@param lnum integer @0-based
---@param start_col? integer @0-based; nil=0
---@return infra.VimGrep.Iterator
function VimGrep:iter_line(bufnr, lnum, start_col)
  local offset = start_col or 0
  return function()
    ---0-based; start inclusive, stop inclusive
    local rel_start, rel_stop = self.impl:match_line(bufnr, lnum, offset)
    if not (rel_start and rel_stop) then return end

    local start, stop = rel_start + offset, rel_stop + offset
    offset = offset + rel_stop

    return start, stop
  end
end

---@param pattern string @vim very-magic regex
---@return infra.VimGrep?
return function(pattern)
  ---as nvim reports no meaningful error on vim.regex(invalid-pattern), make it quiet
  local ok, regex = pcall(vim.regex, pattern)
  if not ok then return end

  return setmetatable({ impl = regex }, VimGrep)
end
