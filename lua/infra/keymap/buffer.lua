local jelly = require("infra.jellyfish")("infra.keymap.buffer")

local api = vim.api

local function noremap(bufnr, mode, lhs, rhs)
  if mode == "v" then return jelly.err("i dont need keymaps for visual+select modes") end

  local rhs_type = type(rhs)
  if rhs_type == "function" then
    api.nvim_buf_set_keymap(bufnr, mode, lhs, "", { silent = false, noremap = true, callback = rhs })
  elseif rhs_type == "string" then
    api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, { silent = false, noremap = true })
  else
    return jelly.err("unexpected rhs type: %s", rhs_type)
  end
end

---@param modes string[]|string
---@param lhs string
---@param rhs string|fun()
local function call(bufnr, modes, lhs, rhs)
  if type(modes) == "string" then return noremap(bufnr, modes, lhs, rhs) end

  for _, mode in ipairs(modes) do
    noremap(bufnr, mode, lhs, rhs)
  end
end

--calling forms
--* M(bufnr, modes, lhs, rhs)
--* M.wraps(bufnr)
--  * bm.n(lhs, rhs)
--  * bm(modes, lhs, rhs)

return setmetatable({
  wraps = function(bufnr)
    return setmetatable({
      n = function(lhs, rhs) noremap(bufnr, "n", lhs, rhs) end,
      v = function(lhs, rhs) noremap(bufnr, "v", lhs, rhs) end,
      i = function(lhs, rhs) noremap(bufnr, "i", lhs, rhs) end,
      t = function(lhs, rhs) noremap(bufnr, "t", lhs, rhs) end,
      c = function(lhs, rhs) noremap(bufnr, "c", lhs, rhs) end,
      x = function(lhs, rhs) noremap(bufnr, "x", lhs, rhs) end,
      o = function(lhs, rhs) noremap(bufnr, "o", lhs, rhs) end,
    }, { __call = function(_, modes, lhs, rhs) return call(bufnr, modes, lhs, rhs) end })
  end,
}, {
  __call = function(_, bufnr, modes, lhs, rhs) return call(bufnr, modes, lhs, rhs) end,
})
