local jelly = require("infra.jellyfish")("infra.keymap.global")

---@param desc string
---@param mode string
---@param lhs string
---@param rhs string|fun()
local function noremap(desc, mode, lhs, rhs)
  if mode == "v" then error("use x+s instead") end

  local rhs_type = type(rhs)
  if rhs_type == "function" then
    vim.api.nvim_set_keymap(mode, lhs, "", { silent = false, noremap = true, callback = rhs, desc = desc })
  elseif rhs_type == "string" then
    vim.api.nvim_set_keymap(mode, lhs, rhs, { silent = false, noremap = true, desc = desc })
  else
    error(string.format("unexpected rhs type: %s", rhs_type))
  end
end

do
  ---@overload fun(desc: string, modes: string|string[], lhs: string, rhs: string|fun())
  local mapper = setmetatable({
    n = function(desc, lhs, rhs) noremap(desc, "n", lhs, rhs) end,
    v = function(desc, lhs, rhs) noremap(desc, "v", lhs, rhs) end,
    i = function(desc, lhs, rhs) noremap(desc, "i", lhs, rhs) end,
    t = function(desc, lhs, rhs) noremap(desc, "t", lhs, rhs) end,
    c = function(desc, lhs, rhs) noremap(desc, "c", lhs, rhs) end,
    x = function(desc, lhs, rhs) noremap(desc, "x", lhs, rhs) end,
    o = function(desc, lhs, rhs) noremap(desc, "o", lhs, rhs) end,
  }, {
    __call = function(_, desc, modes, lhs, rhs)
      if type(modes) == "string" then return noremap(desc, modes, lhs, rhs) end
      for _, mode in ipairs(modes) do
        noremap(desc, mode, lhs, rhs)
      end
    end,
  })

  return mapper
end
