local util = require "telescope._extensions.tasks.util"
local Path = require "plenary.path"
local env = require "telescope._extensions.tasks.generators.env"

local get_opts_string

---Check if there exists a Cargo.toml file, if not return nil.
---Check targets in Cargo.toml and build tasks from them.
---If a binary is currently opened, add a task for running the binary.
---
---TODO: handle adding cargo.toml targets tasks!
---
---cargo run [options] [-- args]
---
---NOTE: this returns only tasks for running rust with cargo
local gen = function()
  local executable = env.get({ "CARGO", "EXECUTABLE" }, "cargo")
  local cargo_toml = env.get({ "CARGO", "CARGO_TOML" }, "Cargo.toml")
  local options = env.get({ "CARGO", "RUN", "OPTIONS" }, {})
  local cargo_env = env.get({ "CARGO", "ENV" }, nil)
  local args = env.get({ "CARGO", "RUN", "ARGS" }, {})

  if not util.parent_dir_includes { cargo_toml } then
    return nil
  end
  local cwd = util.find_current_file_root { cargo_toml }
  local tasks = {}
  if
    vim.fn.expand "%:p:h" == Path:new(cwd):joinpath("src", "bin"):__tostring()
  then
    local cmd = {
      executable,
      "run",
      "--bin",
      vim.fn.expand "%:p:t:r",
    }
    local opts_string = get_opts_string(options)
    local args_string = get_opts_string(args)
    if opts_string then
      table.insert(cmd, opts_string)
    end
    if args_string then
      table.insert(cmd, "--")
      table.insert(cmd, args_string)
    end
    local binary_task = {
      name = "Run current Cargo binary",
      env = cargo_env,
      cmd = cmd,
      cwd = cwd,
    }
    table.insert(tasks, binary_task)
  end
  if next(tasks or {}) then
    return tasks
  end
  return nil
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
      s = s .. k .. "="
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
