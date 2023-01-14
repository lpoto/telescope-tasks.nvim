local env = require "telescope._extensions.tasks.generators.env"

local get_opts_string

---Add a task for running the current python file.
---
---TODO: handle `venv`.
---
---python [options] [package] [arguments]
local gen = function(buf)
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  if filetype ~= "python" then
    return nil
  end

  local executable = env.get({ "PYTHON", "EXECUTABLE" }, "go")
  local arguments = env.get({ "PYTHON", "ARGUMENTS" }, {})
  local python_env = env.get({ "PYTHON", "ENV" }, {})
  local opts = env.get({ "PYTHON", "OPTIONS" }, {})
  local name = vim.api.nvim_buf_get_name(buf)

  local cmd = {
    executable,
  }
  local opts_string = get_opts_string(opts)
  if opts_string then
    table.insert(cmd, opts_string)
  end
  table.insert(cmd, name)
  local args_string = get_opts_string(arguments)
  if args_string then
    table.insert(cmd, args_string)
  end
  return {
    "Run current Python file",
    cmd = cmd,
    env = python_env,
  }
end

get_opts_string = function(opts)
  if not opts or next(opts) == nil then
    return nil
  end
  local s = ""
  for k, v in pairs(opts) do
    if s:len() > 0 then
      s = s .. " "
    end
    if type(k) == "string" then
      s = s .. k .. " "
    end
    if type(v) == "string" then
      s = s .. v
    else
      s = s .. vim.inspect(v)
    end
  end
  if s:len() == 0 then
    return nil
  end
  return s
end

return gen
