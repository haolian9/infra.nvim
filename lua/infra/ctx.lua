local M = {}

local dictlib = require("infra.dictlib")
local fn = require("infra.fn")
local prefer = require("infra.prefer")

local api = vim.api

---@param bufnr integer
---@param logic fun()
function M.noundo(bufnr, logic)
  local bo = prefer.buf(bufnr)
  local orig = bo.undolevels
  bo.undolevels = -1
  local ok, err = xpcall(logic, debug.traceback)
  bo.undolevels = orig
  if not ok then error(err) end
end

---@param bufnr integer
---@param logic fun()
function M.undoblock(bufnr, logic)
  --no need to wrap buf_set_lines with `undojoin`, as it will not close the undo block
  local bo = prefer.buf(bufnr)
  --close previous undo block
  local orig = bo.undolevels
  local ok, err = xpcall(logic, debug.traceback)
  --close this undo block
  bo.undolevels = orig
  if not ok then error(err) end
end

---@param bufnr integer
---@param logic fun()
function M.modifiable(bufnr, logic)
  local bo = prefer.buf(bufnr)

  if bo.modifiable then return logic() end

  bo.modifiable = true
  local ok, result = xpcall(logic, debug.traceback)
  bo.modifiable = false

  if not ok then error(result) end
  return result
end

do
  ---@return integer
  local function get_nonfloat_winid()
    local tabid = api.nvim_get_current_tabpage()
    for _, winid in ipairs(api.nvim_tabpage_list_wins(tabid)) do
      if api.nvim_win_get_config(winid).relative == "" then return winid end
    end
    error("unreachable")
  end
  ---wincall in a land/nonfloatwin in the current tabpage
  ---created for win_set_config(relative=editor) originally
  ---@param logic fun(): any
  ---@return any @depends on logic()
  function M.landwincall(logic)
    return api.nvim_win_call(get_nonfloat_winid(), function() logic() end)
  end
end

---for buf_set_lines/text as them always disorder the cursor
---@param winid integer
---@param logic fun(): any
---@return any @depends on logic()
function M.winview(winid, logic)
  local view = api.nvim_win_call(winid, function() return vim.fn.winsaveview() end)
  local ok, result = xpcall(logic, debug.traceback)
  api.nvim_win_call(winid, function() vim.fn.winrestview(view) end)

  if not ok then error(result) end
  return result
end

---do to all the windows being attached of a bufnr
---@param bufnr integer
---@param logic fun(): any
---@return any @depends on logic()
function M.bufviews(bufnr, logic)
  ---@type {[integer]: any} @{winid: view}
  local views = {}
  do
    local bufinfo = assert(vim.fn.getbufinfo(bufnr)[1])
    for _, winid in ipairs(bufinfo.windows) do
      views[winid] = api.nvim_win_call(winid, function() return vim.fn.winsaveview() end)
    end
  end

  local ok, result = xpcall(logic, debug.traceback)

  for winid, view in pairs(views) do
    api.nvim_win_call(winid, function() vim.fn.winrestview(view) end)
  end

  if not ok then error(result) end
  return result
end

do
  local function resolve_events(raw)
    local t = type(raw)
    if t == "table" then return fn.toset(raw) end
    if t == "string" then return { [raw] = true } end
    error("value error")
  end

  ---@param old string @`,` separated
  ---@param adds {[string]: true}
  ---@return string
  local function resolve_new_setopt(old, adds)
    local union = adds
    if old ~= "" then
      local olds = fn.toset(fn.split_iter(old, ","))
      union = dictlib.merged(olds, adds)
    end
    return fn.join(dictlib.keys(union), ",")
  end

  ---@param event 'all'|string|string[]
  ---@param logic fun()
  function M.noautocmd(event, logic)
    local events = resolve_events(event)

    local old = vim.go.eventignore
    vim.go.eventignore = resolve_new_setopt(old, events)
    local ok, err = xpcall(logic, debug.traceback)
    vim.go.eventignore = old
    if not ok then error(err) end
  end
end

return M
