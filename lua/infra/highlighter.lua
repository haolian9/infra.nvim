local api = vim.api

---cterm* only
---for 'cterm=none', `{bold = nil, underline = nil}` does the same
---@param ns integer
---@return fun(group: string, cterm_spec: {fg: integer|string, bg: integer|string, bold?: boolean, underline?: boolean})
return function(ns)
  return function(group, cterm_spec)
    local spec = {
      ctermfg = cterm_spec.fg,
      ctermbg = cterm_spec.bg,
      cterm = {
        bold = cterm_spec.bold,
        underline = cterm_spec.underline,
      },
    }
    api.nvim_set_hl(ns, group, spec)
  end
end
