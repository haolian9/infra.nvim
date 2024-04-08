local M = {}

local api = vim.api

---known unsupported cases:
---* (quit)
---@param fmt string
---@param ... string|integer
function M.eval(fmt, ...)
  local str = select("#", ...) > 0 and string.format(fmt, ...) or fmt
  local parsed = api.nvim_parse_cmd(str, {})
  ---no cache anymore, for a reason i've forgotten
  api.nvim_cmd(parsed, { output = false })
end

---known unsupported cases:
---* (ll, 1)
---* (cc, 1)
---* (copen, 10)
---@param cmd string
---@param ... string|integer
function M.cmd(cmd, ...)
  local args = select("#", ...) > 0 and { ... } or nil
  api.nvim_cmd({ cmd = cmd, args = args }, { output = false })
end

return setmetatable(M, { __call = function(_, cmd, ...) M.cmd(cmd, ...) end })
