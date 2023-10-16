local api = vim.api

--mandatory fields: group, (buffer vs. pattern)
---@class infra.AugroupCreateOpts
---@field bufnr? integer
---@field pattern? string|string[]
---@field desc? string
---@field callback fun(args: {id: integer, event: string, group?: integer, match: string, buf: integer, file: string, data: any}): nil|true
---@field command? string @exclusive to callback
---@field once? boolean @nil=false
---@field nested? boolean @nil=false
---@field group? integer @should only be set by Augroup internally

local Augroup
do
  ---@class infra.Augroup
  ---@field group integer
  ---@field free_count integer
  ---@field autounlink? boolean @nil=unset
  local Prototype = {}

  Prototype.__index = Prototype

  ---@private
  ---@param event string|string[]
  ---@param opts infra.AugroupCreateOpts
  ---@return integer @autocmd id
  function Prototype:append_aucmd(event, opts)
    opts.group = self.group
    return api.nvim_create_autocmd(event, opts)
  end

  ---@param event string|string[]
  ---@param opts infra.AugroupCreateOpts
  function Prototype:repeats(event, opts)
    assert(opts.once ~= true)
    return self:append_aucmd(event, opts)
  end

  ---@param event string|string[]
  ---@param opts infra.AugroupCreateOpts
  function Prototype:once(event, opts)
    opts.once = true
    return self:append_aucmd(event, opts)
  end

  function Prototype:unlink() api.nvim_del_augroup_by_id(self.group) end

  ---mandatory clearing augroup
  ---@param fmt string
  ---@param ... any
  ---@return infra.Augroup
  function Augroup(fmt, ...)
    local group = api.nvim_create_augroup(string.format(fmt, ...), { clear = true })

    return setmetatable({ group = group, free_count = 0 }, Prototype)
  end
end

local M = {}
do
  ---@param bufnr integer
  ---@param autounlink? boolean @nil=false
  ---@return infra.Augroup
  function M.buf(bufnr, autounlink)
    assert(bufnr ~= nil and bufnr ~= 0)
    if autounlink == nil then autounlink = false end
    local aug = Augroup("aug://buf/%d", bufnr)

    do
      aug.autounlink = false -- set it to false explicitly
      ---@diagnostic disable: invisible
      local orig = aug.append_aucmd
      function aug:append_aucmd(event, opts)
        if self.autounlink and string.lower(event) == "bufwipeout" then error("conflicted with autounlink") end
        opts.buffer = bufnr
        return orig(aug, event, opts)
      end
    end

    if autounlink then
      aug:once("bufwipeout", { callback = function() aug:unlink() end })
      aug.autounlink = autounlink
    end

    return aug
  end

  ---@param winid integer
  ---@param autounlink? boolean @nil=false
  ---@return infra.Augroup
  function M.win(winid, autounlink)
    assert(winid ~= nil and winid ~= 0)
    if autounlink == nil then autounlink = false end
    local aug = Augroup("aug://win/%d", winid)

    do
      aug.autounlink = false -- set it to false explicitly
      ---@diagnostic disable: invisible
      local orig = aug.append_aucmd
      function aug:append_aucmd(event, opts)
        if self.autounlink and string.lower(event) == "winclosed" then error("conflicted with autounlink") end
        return orig(aug, event, opts)
      end
    end

    if autounlink then
      aug:repeats("winclosed", {
        callback = function(args)
          local this_winid = assert(tonumber(args.match))
          if this_winid ~= winid then return end
          aug:unlink()
          return true
        end,
      })
      aug.autounlink = autounlink
    end

    return aug
  end
end

---@overload fun(name: string): infra.Augroup
local mod = setmetatable({}, { __index = M, __call = function(_, name) return Augroup(name) end })

return mod
