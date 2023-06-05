local Default = require "telescope-tasks.model.default_generator"
local util = require "telescope-tasks.util"

---Add a task for running the current python file.
---
---TODO: handle `venv`.
local python = Default:new {
  errorformat = '%C\\ %.%#,%A\\ \\ File\\ "%f"\\,'
    .. "\\ line\\ %l%.%#,%Z%[%^\\ ]%\\@=%m",
  opts = {
    name = "Default Python Generator",
    experimental = true,
  },
}

local get_binary

function python.generator(buf)
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  if filetype ~= "python" then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(buf)
  local binary = get_binary()

  local cmd = {
    binary,
    name,
  }
  local t = {
    "Run current Python file",
    cmd = cmd,
    filename = name,
    keywords = {
      "python",
      name,
    },
  }
  local env = util.get_env "python"
  if type(env) == "table" and next(env) then
    t.env = env
  end
  return t
end

function get_binary()
  local binary = util.get_binary "python"
  if type(binary) ~= "string" then
    binary = "python"
    if vim.fn.executable(binary) == 0 and vim.fn.executable "python3" == 1 then
      return "python3",
        nil,
        "'python' is not executable, using 'python3' instead"
    end
  end
  if vim.fn.executable(binary) == 0 then
    return binary, "'" .. binary .. "' is not executable", nil
  end
  return binary
end

function python.healthcheck()
  local binary, err, warn = get_binary()
  if err ~= nil then
    vim.health.warn(err, {
      "Install 'python' or set a different binary with vim.g.telescope_tasks = { binaries = { python=<new-binary> }}",
    })
  elseif warn ~= nil then
    vim.health.warn(warn)
  else
    vim.health.ok("'" .. binary .. "' is executable")
  end
end

return python
