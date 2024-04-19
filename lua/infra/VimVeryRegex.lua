local strlib = require("infra.strlib")

---it enforce using very magic pattern for convenient interactive experience
---@param re string @very magic regex
---@return vim.Regex
return function(re)
  if not strlib.startswith(re, "\\v") then re = "\\v" .. re end

  return vim.regex(re)
end
