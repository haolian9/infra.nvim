local M = {}

local dictlib = require("infra.dictlib")
local fn = require("infra.fn")
local facts = require("infra.rifts.facts")
local geo = require("infra.rifts.geo")

local api = vim.api

---@class infra.rifts.BasicOpenOpts
---@field relative   'editor'|'win'|'cursor'|'mouse'
---@field win?       integer @for relative=win
---@field anchor?    'NW'|'NE'|'SW'|'SE' @nil=NW
---@field width?     integer
---@field height?    integer
---@field row?       integer
---@field col?       integer
---@field focusable? boolean @nil=true
---@field zindex?    integer @nil=50; ins pum=100, cmdline pum=250
---@field style?     'minimal' @nil=minimal
---@field border?    'none'|'single'|'double'|'rounded'|'solid'|'shadow'|string[][]
---@field title?     string|{[1]: string, [2]: string}[] @(text, higroup)
---@field title_pos? 'left'|'center'|'right'
---@field noautocmd? boolean @nil=false

local resolve_border
do
  local border_widths = { none = 0, single = 1, double = 2, rounded = 1, solid = 1, shadow = 2 }
  ---@param basic infra.rifts.BasicOpenOpts
  ---@return integer
  function resolve_border(basic)
    assert(not (basic.border and type(basic.border) == "table"), "not support opts.border table")
    return border_widths[basic.border] or 0
  end
end

do
  ---@class infra.rifts.ExtraOpenOpts
  ---@field width       number @<1, &columns%; >=1, columns
  ---@field height      number @<1, &lines%; >=1, lines
  ---@field horizontal? 'mid'|'left'|'right' @nil=mid
  ---@field vertical?   'mid'|'top'|'bot' @nil=mid
  ---@field ns          nil|integer|false @nil=rifts.ns, false=no set

  ---@param basic infra.rifts.BasicOpenOpts
  ---@param extra? infra.rifts.ExtraOpenOpts
  ---@return table
  local function resolve_winopts(basic, extra)
    if extra == nil then return basic end

    return dictlib.merged(basic, geo.editor(extra.width, extra.height, extra.horizontal, extra.vertical, resolve_border(basic)))
  end

  ---opinionated nvim_open_win
  ---* relative     to editor
  ---* width/height float|integer
  ---* horizontal   for col
  ---* vertical     for row
  ---
  ---@param bufnr integer
  ---@param enter boolean
  ---@param basic_opts infra.rifts.BasicOpenOpts
  ---@param extra_opts? infra.rifts.ExtraOpenOpts
  ---@return integer
  function M.fragment(bufnr, enter, basic_opts, extra_opts)
    assert(basic_opts ~= nil)
    assert(basic_opts.relative == "editor")

    if extra_opts == nil then
      local winid = api.nvim_open_win(bufnr, enter, basic_opts)
      api.nvim_win_set_hl_ns(winid, facts.ns)
      return winid
    end

    local winid = api.nvim_open_win(bufnr, enter, resolve_winopts(basic_opts, extra_opts))
    if extra_opts.ns == false then return winid end
    api.nvim_win_set_hl_ns(winid, fn.nilor(extra_opts.ns, facts.ns))
    return winid
  end
end

do
  ---@param basic infra.rifts.BasicOpenOpts
  ---@return table
  local function resolve_winopts(basic)
    assert(not (basic.border and type(basic.border) == "table"), "not support opts.border table")
    return dictlib.merged(basic, geo.fullscreen(resolve_border(basic)))
  end

  ---@param bufnr integer
  ---@param enter boolean
  ---@param basic_opts infra.rifts.BasicOpenOpts
  ---@param extra_opts? {ns: nil|integer|false}
  function M.fullscreen(bufnr, enter, basic_opts, extra_opts)
    assert(basic_opts ~= nil)
    assert(basic_opts.relative == "editor")
    extra_opts = extra_opts or {}

    local winid = api.nvim_open_win(bufnr, enter, resolve_winopts(basic_opts))
    if extra_opts.ns ~= false then api.nvim_win_set_hl_ns(winid, extra_opts.ns or facts.ns) end

    return winid
  end
end

return M
