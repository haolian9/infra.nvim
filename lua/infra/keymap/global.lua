local jelly = require("infra.jellyfish")("infra.keymap.global")

local function noremap(mode, lhs, rhs)
  local rhs_type = type(rhs)
  if rhs_type == "function" then
    vim.api.nvim_set_keymap(mode, lhs, "", { silent = false, noremap = true, callback = rhs })
  elseif rhs_type == "string" then
    vim.api.nvim_set_keymap(mode, lhs, rhs, { silent = false, noremap = true })
  else
    return jelly.err("unexpected rhs type: %s", rhs_type)
  end
end

return setmetatable({
  n = function(lhs, rhs) noremap("n", lhs, rhs) end,
  v = function(lhs, rhs) noremap("v", lhs, rhs) end,
  i = function(lhs, rhs) noremap("i", lhs, rhs) end,
  t = function(lhs, rhs) noremap("t", lhs, rhs) end,
  c = function(lhs, rhs) noremap("c", lhs, rhs) end,
  x = function(lhs, rhs) noremap("x", lhs, rhs) end,
  o = function(lhs, rhs) noremap("o", lhs, rhs) end,
}, {
  ---@param modes string[]
  ---@param lhs string
  ---@param rhs string|fun()
  __call = function(_, modes, lhs, rhs)
    for _, mode in ipairs(modes) do
      noremap(mode, lhs, rhs)
    end
  end,
})
