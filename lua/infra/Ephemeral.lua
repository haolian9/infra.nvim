local prefer = require("infra.prefer")

local api = vim.api

---to create ephemeral buffers with mandatory buffer-options

---@class infra.ephemerals.CreateOptions
---@field undolevels? integer @nil=-1
---@field bufhidden? string @nil="wipe"
---@field modifiable? boolean @nil=true

local resolve_opts
do
  local defaults = {
    undolevels = -1,
    bufhidden = "wipe",
    modifiable = true,
  }

  ---@param specified? infra.ephemerals.CreateOptions
  ---@return infra.ephemerals.CreateOptions
  function resolve_opts(specified)
    if #specified == 0 then return defaults end
    ---@diagnostic disable-next-line: param-type-mismatch
    return setmetatable(specified, { __index = defaults })
  end
end

---defaults
---* buflisted=false
---* buftype=nofile
---* swapfile=off
---* modeline=off
---* undolevels=-1
---* bufhidden=wipe
---* modifiable=true @but with lines, it'd be false
---
---@param opts? infra.ephemerals.CreateOptions
---@param lines? (string|string[])[]
---@return integer
return function(opts, lines)
  opts = opts or {}
  local has_lines = lines ~= nil and #lines > 0
  if has_lines and opts.modifiable == nil then opts.modifable = false end
  --order matters, as we access .modifiabe above
  opts = resolve_opts(opts)

  local bufnr = api.nvim_create_buf(false, true)

  local bo = prefer.buf(bufnr)
  ---intented to no use pairs() here, to keep things obviously
  bo.bufhidden = opts.bufhidden

  if has_lines then --avoid being recorded by the undo history
    bo.undolevels = -1
    local offset = 0
    ---@diagnostic disable-next-line: param-type-mismatch
    for _, line in ipairs(lines) do
      local lntype = type(line)
      if lntype == "string" then
        api.nvim_buf_set_lines(bufnr, offset, offset + 1, false, { line })
        offset = offset + 1
      elseif lntype == "table" then
        api.nvim_buf_set_lines(bufnr, offset, offset + #line, false, line)
        offset = offset + #line
      else
        error("unreachable: unknown line type: " .. lntype)
      end
    end
    assert(api.nvim_buf_line_count(bufnr) == offset)
  end

  bo.undolevels = opts.undolevels
  bo.modifiable = opts.modifiable

  return bufnr
end