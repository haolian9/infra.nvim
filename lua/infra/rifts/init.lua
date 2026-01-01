local M = {}

local oop = require("infra.oop")

M.ns = require("infra.rifts.facts").ns
M.geo = oop.proxy("infra.rifts.geo")
M.open = oop.proxy("infra.rifts.open")

return M
