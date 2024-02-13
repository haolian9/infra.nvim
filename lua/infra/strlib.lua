local M = {}

--forced to plain-match
---@param haystack string
---@param substr string
---@param start? number
function M.find(haystack, substr, start) return string.find(haystack, substr, start, true) end

do
  local function rfind(haystack, needle)
    assert(#needle >= 1)
    for i = #haystack - #needle, 1, -1 do
      local found = string.sub(haystack, i, i + #needle - 1)
      if found == needle then return i end
    end
  end

  ---@param haystack string
  ---@param needle string
  ---@return nil|number
  function M.rfind(haystack, needle)
    local impl
    do
      local ok, cthulhu = pcall(require, "cthulhu")
      --the ffi version is 4x faster but no difference on memory usage
      impl = ok and cthulhu.str.rfind or rfind
    end

    M.rfind = impl

    return impl(haystack, needle)
  end
end

---@param str string
---@return string[]
function M.tolist(str)
  local list = {}
  for i = 1, #str do
    table.insert(list, string.sub(str, i, i))
  end
  return list
end

---@param str string
---@return {[string]: true}
function M.toset(str)
  local set = {}
  for i = 1, #str do
    set[string.sub(str, i, i)] = true
  end
  return set
end

do
  local blanks = M.toset("\t\n ")

  local function lstrip_pos(str, mask)
    local start_at = 1
    -- +1 for case ('/', '/')
    for i = 1, #str + 1 do
      local char = string.sub(str, i, i)
      start_at = i
      if mask[char] == nil then break end
    end
    return start_at
  end

  local function rstrip_pos(str, mask)
    local stop_at = #str
    -- -1 for case ('/', '/')
    for i = #str, 1 - 1, -1 do
      local char = string.sub(str, i, i)
      stop_at = i
      if mask[char] == nil then break end
    end
    return stop_at
  end

  ---@param str string
  ---@param chars? string @nil=blank chars
  ---@return string
  function M.lstrip(str, chars)
    local mask = chars and M.toset(chars) or blanks
    local start_at = lstrip_pos(str, mask)

    if start_at == 1 then return str end
    return string.sub(str, start_at, #str)
  end

  ---@param str string
  ---@param chars? string @nil=blank chars
  ---@return string
  function M.rstrip(str, chars)
    local mask = chars and M.toset(chars) or blanks
    local stop_at = rstrip_pos(str, mask)

    if stop_at == #str then return str end
    return string.sub(str, 1, stop_at)
  end

  ---@param str string
  ---@param chars? string @nil=blank chars
  ---@return string
  function M.strip(str, chars)
    local mask = chars and M.toset(chars) or blanks
    local start_at = lstrip_pos(str, mask)
    local stop_at = rstrip_pos(str, mask)

    if start_at == 1 and stop_at == #str then return str end
    return string.sub(str, start_at, stop_at)
  end
end
---@param a string
---@param b string
---@return boolean
function M.startswith(a, b)
  if #b > #a then return false end
  if #b == #a then return a == b end
  return string.sub(a, 1, #b) == b
end

---@param a string
---@param b string
---@return boolean
function M.endswith(a, b)
  if #b > #a then return false end
  if #b == #a then return a == b end
  return string.sub(a, -#b) == b
end

return M
