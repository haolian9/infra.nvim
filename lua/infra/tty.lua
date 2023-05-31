-- direct access to neovim's tty

local unsafe = require("infra.unsafe")

local M = {}

---@class infra.tty.TtyReader
---@field private file file*
local TtyReader = {}
do
  TtyReader.__index = TtyReader

  ---@return string,number
  function TtyReader:read1()
    local char = self.file:read(1)
    assert(char ~= nil, "tty can not be closed")
    local code = string.byte(char)
    return char, code
  end

  function TtyReader:close() return self.file:close() end

  function TtyReader:guarded_close(callback)
    local ok, err = pcall(callback)
    self:close()
    assert(ok, err)
  end

  function TtyReader.new()
    -- should be blocking reads, no uv.new_tty here
    -- fd/{1,2} should be the same tty fd
    assert(unsafe.isatty(1), "unreachable: stdout of nvim is not a tty")
    local file, open_err = io.open("/proc/self/fd/1", "rb")
    assert(file ~= nil, open_err)

    return setmetatable({ file = file }, TtyReader)
  end
end

local state = {
  reader = TtyReader.new(),
}

function state.read1() return state.reader:read1() end

--read n chars from nvim's tty exclusively, blockingly
--* <esc> to cancel; #return == 0
--* <space> to finish early; #return < n
--
---@param n number @n > 0
---@return string @#return >= 0
function M.read_chars(n)
  assert(n > 0, "no need to read")

  local chars = {}

  -- keep **blocking the process** until get enough chars
  for char, code in state.read1 do
    if code >= 0x21 and code <= 0x7e then
      -- printable
      table.insert(chars, char)
    elseif code == 0x1b then
      -- cancelled by esc
      chars = {}
      break
    elseif code == 0x20 or code == 0x0d then
      -- finished by space, cr
      break
    else
      -- regardless of esc-sequence
    end
    if #chars >= n then break end
  end

  return table.concat(chars, "")
end

return M
