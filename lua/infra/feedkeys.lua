---terms:
---* keys: the same as lhs, human readable
---* codes: bytes, for machine

local M = {}

local dictlib = require("infra.dictlib")

local api = vim.api

local to_codes
do
  local cache = dictlib.CappedDict(512)

  --nvim_replace_termcodes has a mysterious signature
  --cached nvim_replace_termcodes with:
  --* from_part=true
  --* do_lt=false
  --* special=true
  ---@param keys string @sequences like lhs
  ---@return string
  function to_codes(keys)
    local found = cache[keys]
    if found then return found end

    local missing = api.nvim_replace_termcodes(keys, true, false, true)
    cache[keys] = missing
    return missing
  end
end

---@alias Mode 'n'|'x'|'nx'|'ni'

---@param keys string
---@param mode Mode
function M.keys(keys, mode) M.codes(to_codes(keys), mode) end

---@param codes string
---@param mode Mode
function M.codes(codes, mode) api.nvim_feedkeys(codes, mode, false) end

return setmetatable(M, {
  __call = function(_, keys, mode) return M.keys(keys, mode) end,
})

