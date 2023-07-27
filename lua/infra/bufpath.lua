local M = {}

local fs = require("infra.fs")
local jelly = require("infra.jellyfish")("infra.bufpath")
local prefer = require("infra.prefer")

local api = vim.api

---based on buftype and bufname
---@param bufnr integer
---@param should_exist? boolean @nil=false
---@return string? @absolute file path
function M.file(bufnr, should_exist)
  assert(bufnr ~= nil and bufnr ~= 0)

  if prefer.bo(bufnr, "buftype") ~= "" then return end

  local bufname = api.nvim_buf_get_name(bufnr)
  if bufname == "" then return end

  local path
  if fs.is_absolute(bufname) then
    path = bufname
  else
    path = vim.fn.fnamemodify(bufname, "%:p")
  end

  if should_exist and not fs.exists(path) then return end

  return path
end

---based on buftype={help,""} and bufname
---@param bufnr integer
---@return string @absolute directory path
function M.dir(bufnr)
  assert(bufnr ~= nil and bufnr ~= 0)

  --can not use project.working_root() here due to cyclic import
  local getcwd = vim.fn.getcwd

  if prefer.bo(bufnr, "buftype") ~= "" then return getcwd() end

  local bufname = api.nvim_buf_get_name(bufnr)
  if bufname == "" then return getcwd() end

  if fs.is_absolute(bufname) then return fs.parent(bufname) end

  return vim.fn.fnamemodify(bufname, "%:p:h")
end

return M