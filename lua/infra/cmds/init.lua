local M = {}

local ni = require("infra.ni")
local oop = require("infra.oop")

do
  local default_attrs = { nargs = 0 }

  ---@param name string
  ---@param handler fun(args: infra.cmds.Args)|string
  ---@param attrs? infra.cmds.Attrs
  function M.create(name, handler, attrs)
    attrs = attrs or default_attrs
    ni.create_user_command(name, handler, attrs)
  end
end

M.ArgComp = oop.proxy("infra.cmds.ArgComp")
M.FlagComp = oop.proxy("infra.cmds.FlagComp")
M.Spell = oop.proxy("infra.cmds.Spell")
M.cast = oop.proxy("infra.cmds.cast")

return M
