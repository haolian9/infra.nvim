local M = {}

local fn = require("infra.fn")
local listlib = require("infra.listlib")
local logging = require("infra.logging")
local tail = require("infra.tail")

local uv = vim.loop

local facts = {
  stdout_fpath = logging.newfile("infra.subprocess"),
  forever = math.pow(2, 31) - 1,
}

local redirect_to_file
do
  -- NB: meant to be dangling; writes can be interleaving between subprocesses
  local fd = uv.fs_open(facts.stdout_fpath, "a", tonumber("600", 8))

  ---@param done function|nil
  function redirect_to_file(read_pipe, done)
    uv.read_start(read_pipe, function(err, data)
      assert(not err, err)
      if data then
        uv.fs_write(fd, data)
      else
        read_pipe:close()
        if done ~= nil then done() end
      end
    end)
  end
end

-- each chunk of read from stdout can contains multiple lines, and may not ends with `\n`
---@param chunks string[][]
local function split_stdout(chunks)
  local del = "\n"
  local chunk_iter = listlib.iter(chunks)
  local line_iter = nil
  local short = nil

  return function()
    while true do
      if line_iter == nil then
        local chunk = chunk_iter()
        if chunk == nil then return end
        line_iter = fn.split_iter(chunk, del, nil, true)
      end

      local line = line_iter()
      if line ~= nil then
        if line:sub(#line) == del then
          if short ~= nil then
            line = short .. line
            short = nil
          end
          return line:sub(0, #line - 1)
        else
          -- last part but not a complete line
          assert(short == nil)
          short = line
        end
      else
        line_iter = nil
      end
    end
  end
end

---@param bin string
---@param opts? {args: string[]?, cwd: string?} @see uv.spawn(opts)
---@param capture_stdout boolean? @nil=false
---@return {pid: number, exit_code: number, stdout: fun():string}
function M.run(bin, opts, capture_stdout)
  opts = opts or {}
  if capture_stdout == nil then capture_stdout = false end

  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()
  local rc

  opts["stdio"] = { nil, stdout, stderr }

  local proc_t, pid = uv.spawn(bin, opts, function(code) rc = assert(code) end)
  if proc_t == nil then error(pid) end

  local stdout_lines
  if capture_stdout then
    local chunks = {}
    uv.read_start(stdout, function(err, data)
      assert(not err, err)
      if data then
        table.insert(chunks, data)
      else
        stdout:close()
      end
    end)
    stdout_lines = split_stdout(chunks)
  else
    redirect_to_file(stdout)
    stdout_lines = function() end
  end

  redirect_to_file(stderr)

  vim.wait(facts.forever, function() return rc ~= nil end, 100)

  return { pid = pid, exit_code = rc, stdout = stdout_lines }
end

---@param bin string
---@param opts {args: string[]?}? see uv.spawn(opts)
---@param stdout_callback fun(stdout: (fun():string?))
---@param exit_callback fun(code: number)
function M.spawn(bin, opts, stdout_callback, exit_callback)
  assert(stdout_callback ~= nil and exit_callback)
  opts = opts or {}

  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()

  opts["stdio"] = { nil, stdout, stderr }

  uv.spawn(bin, opts, function(code) exit_callback(code) end)

  local chunks = {}
  uv.read_start(stdout, function(err, data)
    assert(not err, err)
    if data then
      table.insert(chunks, data)
    else
      stdout:close()
      vim.schedule(function() stdout_callback(split_stdout(chunks)) end)
    end
  end)

  redirect_to_file(stderr)
end

function M.tail_logs() tail.split_below(facts.stdout_fpath) end

return M
