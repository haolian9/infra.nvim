-- design choices
-- * only buffer for each fpath
-- * only one window for each tab

local M = {}

local api = vim.api
local bufrename = require("infra.bufrename")
local ex = require("infra.ex")
local prefer = require("infra.prefer")

---@class canvas
local canvas = {
  -- {fpath: (bufnr, {tabpage: winid})}
  --
  ---@type { [string]: {bufnr: number, tab_win: table<number, number>} }
  store = {},

  ---@param self canvas
  ---@return number?,number? @bufnr,winid
  get = function(self, fpath, tabpage)
    local held = self.store[fpath]
    if held == nil then return end

    if not api.nvim_buf_is_valid(held.bufnr) then
      self.store[fpath] = nil
      return
    end

    local held_win = held.tab_win[tabpage]
    if held_win == nil or not api.nvim_win_is_valid(held_win) then
      held.tab_win[tabpage] = nil
      return held.bufnr, nil
    end

    return held.bufnr, held_win
  end,

  ---@param self canvas
  set = function(self, fpath, bufnr, tabpage, winid)
    local held = self.store[fpath]
    if held == nil then
      self.store[fpath] = { bufnr = bufnr, tab_win = { [tabpage] = winid } }
      return
    end

    assert(held.bufnr == bufnr)

    local held_win = held.tab_win[tabpage]
    if held_win == nil then
      held.tab_win[tabpage] = winid
      return
    end

    if held_win == winid then return end

    assert(not api.nvim_win_is_valid(held_win))
    held.tab_win[tabpage] = winid
  end,
}

local function tail(bufnr, winid, fpath)
  assert(bufnr and winid and fpath)
  local height = math.max(100, vim.fn.winheight(winid))
  local scrollback = math.floor(height / 2)

  api.nvim_create_autocmd("TermOpen", {
    buffer = bufnr,
    once = true,
    callback = function() prefer.bo(bufnr, "scrollback", scrollback) end,
  })

  local job
  do
    local cmd = { "tail", "-n", height + scrollback, "-f", fpath }
    job = vim.fn.termopen(cmd, { stderr_buffered = false, stdout_buffered = false, stdin = "" })
    --follow
    api.nvim_win_set_cursor(winid, { api.nvim_buf_line_count(bufnr), 0 })
  end

  -- cleanup the process and buffer
  api.nvim_create_autocmd("WinClosed", {
    callback = function(args)
      if winid ~= tonumber(args.match) then return end
      vim.fn.jobstop(job)
      api.nvim_buf_delete(bufnr, { force = true })
      return true
    end,
  })

  bufrename(bufnr, string.format("tail://%s", fpath))
end

function M.split_below(fpath)
  assert(fpath ~= nil)

  local tabpage = api.nvim_get_current_tabpage()

  local bufnr, winid
  do
    local held_bufnr, held_win_id = canvas:get(fpath, tabpage)
    if held_bufnr and held_win_id then return end
    bufnr = held_bufnr or api.nvim_create_buf(false, true)
    if held_win_id ~= nil then
      winid = held_win_id
    else
      ex("rightbelow split")
      winid = api.nvim_get_current_win()
      api.nvim_win_set_height(winid, 10)
      prefer.wo(winid, "winfixheight", true)
    end
  end

  api.nvim_win_set_buf(winid, bufnr)
  canvas:set(fpath, bufnr, tabpage, winid)
  tail(bufnr, winid, fpath)
end

return M
