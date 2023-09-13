---@alias infra.cmds.CompFn fun(prompt: ""|string, line: string, cursor: 1|integer): string[]

do
  ---:h command-complete
  ---@enum infra.cmds.CompLit
  local Complete = {
    ---file names in argument list
    arglist = "arglist",
    ---autocmd groups
    augroup = "augroup",
    ---buffer names
    buffer = "buffer",
    ---:behave suboptions
    behave = "behave",
    ---color schemes
    color = "color",
    ---Ex command (and arguments)
    command = "command",
    ---compilers
    compiler = "compiler",
    ---directory names
    dir = "dir",
    ---environment variable names
    environment = "environment",
    ---autocommand events
    event = "event",
    ---Vim expression
    expression = "expression",
    ---file and directory names
    file = "file",
    ---file and directory names in |'path'|
    file_in_path = "file_in_path",
    ---filetype names |'filetype'|
    filetype = "filetype",
    ---function name
    ["function"] = "function",
    ---help subjects
    help = "help",
    ---highlight groups
    highlight = "highlight",
    ---:history suboptions
    history = "history",
    ---locale names (as output of locale -a)
    locale = "locale",
    ---Lua expression
    lua = "lua",
    ---buffer argument
    mapclear = "mapclear",
    ---mapping name
    mapping = "mapping",
    ---menus
    menu = "menu",
    ---|:messages| suboptions
    messages = "messages",
    ---options
    option = "option",
    ---optional package |pack-add| names
    packadd = "packadd",
    ---Shell command
    shellcmd = "shellcmd",
    ---|:sign| suboptions
    sign = "sign",
    ---syntax file names |'syntax'|
    syntax = "syntax",
    ---|:syntime| suboptions
    syntime = "syntime",
    ---tags
    tag = "tag",
    ---tags, file names are shown when CTRL-D is hit
    tag_listfiles = "tag_listfiles",
    ---user names
    user = "user",
    ---user variables
    var = "var",
  }

  local _ = Complete
end

do
  ---:h command-addr
  ---@enum infra.cmds.Addr
  local UsercmdAddr = {
    ---Range of lines (this is the default for -range)
    lines = "lines",
    ---Range for arguments
    arguments = "arguments",
    ---Range for buffers (also not loaded buffers)
    buffers = "buffers",
    ---Range for loaded buffers
    loaded_buffers = "loaded_buffers",
    ---Range for windows
    windows = "windows",
    ---Range for tab pages
    tabs = "tabs",
    ---Range for quickfix entries
    quickfix = "quickfix",
    ---Other kind of range; can use ".", "$" and "%" as with "lines" (this is the default for -count)
    other = "other",
  }
  local _ = UsercmdAddr
end

---:h command-attributes
---@class infra.cmds.Attrs
---
---@field nargs 0|1|'*'|'?'|'+'
---@field complete? infra.cmds.CompLit|infra.cmds.CompFn
---
---@field range? true|'%'|integer
---@field count? true|integer
---@field addr? infra.cmds.Addr
---
---The command can take a ! modifier (like :q or :w)
---@field bang? true
---The command can be followed by a "|" and another command. A "|" inside the command argument is not allowed then. Also checks for a " to start a comment.
---@field bar? true
---The first argument to the command can be an optional register name (like :del, :put, :yank).
---@field register? true
---:h command-buffer
---The command will only be available in the current buffer
---@field buffer? true|integer
---Do not use the location of where the user command was defined for verbose messages, use the location of where the user command was invoked.
---@field keepscript? true

---@class infra.cmds.ArgsSmods
---@field browse        boolean
---@field confirm       boolean
---@field emsg_silent   boolean
---@field hide          boolean
---@field horizontal    boolean
---@field keepalt       boolean
---@field keepjumps     boolean
---@field keepmarks     boolean
---@field keeppatterns  boolean
---@field lockmarks     boolean
---@field noautocmd     boolean
---@field noswapfile    boolean
---@field sandbox       boolean
---@field silent        boolean
---@field split         ""|string
---@field tab           -1|integer
---@field unsilent      boolean
---@field verbose       -1|integer
---@field vertical      boolean

---:h command-args
---@class infra.cmds.Args
---@field args   ""|string
---@field bang   boolean
---@field count  integer
---@field fargs  string[]
---@field line1  integer
---@field line2  integer
---@field mods   ""|string
---@field name   string
---@field range  integer
---@field reg    ""|string
---@field smod infra.cmds.ArgsSmods
