local M = {}

--forced to plain-match
---@param haystack string
---@param substr string
---@param start? number
function M.find(haystack, substr, start) return string.find(haystack, substr, start, true) end

---@param haystack string
---@param substr string
---@return nil|number
function M.rfind(haystack, substr)
  assert(#substr >= 1)
  for i = #haystack - #substr, 1, -1 do
    local found = string.sub(haystack, i, i + #substr - 1)
    if found == substr then return i end
  end
end

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
---@param chars string
---@return string
function M.lstrip(str, chars)
  local mask = M.toset(chars)
  local start_at = lstrip_pos(str, mask)

  if start_at == 1 then return str end
  return string.sub(str, start_at, #str)
end

---@param str string
---@param chars string
---@return string
function M.rstrip(str, chars)
  local mask = M.toset(chars)
  local stop_at = rstrip_pos(str, mask)

  if stop_at == #str then return str end
  return string.sub(str, 1, stop_at)
end

---@param str string
---@param chars string
---@return string
function M.strip(str, chars)
  local mask = M.toset(chars)
  local start_at = lstrip_pos(str, mask)
  local stop_at = rstrip_pos(str, mask)

  if start_at == 1 and stop_at == #str then return str end
  return string.sub(str, start_at, stop_at)
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

---@param s string
---@return string
function M.ltrim(s) return M.lstrip(s, "\t ") end

return M
