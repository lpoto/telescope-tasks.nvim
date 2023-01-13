local util = require "telescope._extensions.tasks.util"
local env = require "telescope._extensions.tasks.generators.env"

---Check if there exists a go.mod file
---in any of the parent directories. If so,  return
---a task that runs the go project from the same directory the go.mod
---file is in, else return the task that runs just the current go file.
---
---go run [build flags] [-exec xprog] package [arguments...]
---
return function(buf)
  local executable = env.get({ "GO", "EXECUTABLE" }, "go")
  local mod_file = env.get({ "GO", "MOD_FILE" }, "go.mod")
  local build_flags = env.get({ "GO", "RUN", "BUILD_FLAGS" }, {})
  local arguments = env.get({ "GO", "RUN", "ARGUMENTS" }, {})
  local xprog = env.get({ "GO", "RUN", "XPROG" }, false)
  local go_env = env.get({ "GO", "ENV" }, nil)
  local package
  local cwd
  local name

  if util.parent_dir_includes { mod_file } then
    package = "."
    cwd = util.find_current_file_root { mod_file }
    name = "Run current Go project"
  else
    package = vim.api.nvim_buf_get_name(buf)
    cwd = nil
    name = "Run current Go file"
  end

  local cmd = {
    executable,
    "run",
  }
  if next(build_flags) then
    table.insert(cmd, table.concat(build_flags, " "))
  end
  if xprog == true then
    table.insert(cmd, "-exec xprog")
  end

  table.insert(cmd, package)

  if next(arguments) then
    table.insert(cmd, table.concat(arguments, " "))
  end

  return {
    name,
    cmd = cmd,
    env = go_env,
    cwd = cwd,
  }
end
