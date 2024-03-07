local api = vim.api

--facts:
--* two kind of keymaps: global, buffer-local
--* the buffer-local one always gets fired solely, even the global one exists
--* mapcheck() tells nothing about if the map is buffer-local or global
--* maparg() returns only one definition, .buffer=0|1
--* maparg/mapset has no bufnr param, so nvim_buf_call should be used

---@class infra.BufSubmode.KeymapDump
---@field buffer 0|1
---@field mode string @injected in keymap_dump_locally

---NB: should be wrapped by nvim_buf_call if needed
---@param mode string
---@param lhs string
---@return infra.BufSubmode.KeymapDump?
local function keymap_dump_locally(mode, lhs)
  ---@type infra.BufSubmode.KeymapDump
  local dump = vim.fn.maparg(lhs, mode, false, true)

  --no buffer-local one nor global one
  if dump.buffer == nil then return nil end
  --the global one exists, but not the buffer-local one
  if dump.buffer == 0 then return nil end

  assert(dump.buffer == 1)
  dump.mode = mode
  return dump
end

---NB: should be wrapped by nvim_buf_call if needed
---@param dump infra.BufSubmode.KeymapDump
local function keymap_restore_locally(dump)
  assert(dump.mode ~= nil)
  assert(dump.buffer == 1)
  vim.fn.mapset(dump.mode, false, dump)
end

---@param bufnr integer
---@param mode_lhs_pairs {[1]: string, [2]: string}[] @[(mode, lhs)]
---@return fun() @deinit
return function(bufnr, mode_lhs_pairs)
  local defs = {} --need to be restored
  local undefs = {} --need to be unset

  api.nvim_buf_call(bufnr, function()
    for _, pair in ipairs(mode_lhs_pairs) do
      local dump = keymap_dump_locally(unpack(pair))
      if dump then
        table.insert(defs, dump)
      else
        table.insert(undefs, pair)
      end
    end
  end)

  return function()
    if #defs > 0 then api.nvim_buf_call(bufnr, function()
      for _, dump in ipairs(defs) do
        keymap_restore_locally(dump)
      end
    end) end

    for _, pair in ipairs(undefs) do
      api.nvim_buf_del_keymap(bufnr, unpack(pair))
    end
  end
end
