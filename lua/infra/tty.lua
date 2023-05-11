-- direct access to neovim's tty

local unsafe = require("infra.unsafe")

local M = {}

local function create_tty()
  -- should be blocking reads, no uv.new_tty here
  -- fd/{1,2} should be the same tty fd
  assert(unsafe.isatty(1), "unreachable: stdout of nvim is not a tty")
  local file, open_err = io.open("/proc/self/fd/1", "rb")
  assert(file ~= nil, open_err)

  local function reader()
    local char = file:read(1)
    assert(char ~= nil, "tty can not be closed")
    local code = string.byte(char)
    return char, code
  end

  local function close() return file:close() end

  local function context(callback)
    local ok, err = pcall(callback)
    close()
    assert(ok, err)
  end

  return {
    tty = file,
    reader = reader,
    close = close,
    context = context,
  }
end

--read n chars from nvim's tty exclusively, blockingly
--* <esc> to cancel; #return == 0
--* <space> to finish early; #return < n
--
---@param n number @n > 0
---@return string @#return >= 0
function M.read_chars(n)
  assert(n > 0, "no need to read")

  local tty = create_tty()
  local chars = {}

  -- keep **blocking the process** until get enough chars
  tty.context(function()
    for char, code in tty.reader do
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
  end)

  return table.concat(chars, "")
end

return M
