local util = require "telescope._extensions.tasks.util"
local setup = require "telescope._extensions.tasks.setup"
local env = require "telescope._extensions.tasks.generators.env"
local Path = require "plenary.path"
local Default = require "telescope._extensions.tasks.model.default_generator"

---Generate tasks for running go projects in subdirectories,
---or a task for running the current file if there is no
---go.mod files.
---
---go run [build flags] [-exec xprog] package [arguments...]
---go build [build flags]
---
local go = Default:new {
  errorformat = "%f:%l.%c-%[%^:]%#:\\ %m,%f:%l:%c:\\ %m",
  opts = {
    name = "Default Go Generator",
    experimental = true,
  },
}

local is_main_file
local build_current_file_task
local build_project_task
local get_opts_string

--- Build tasks by finding main go files in the subdirectories.
--- If there are go.mod files, return tasks for running projects
--- otherise returns just a task for running the current go file.
function go.generator(buf)
  local tasks = {}

  if not go:state() then
    return
  end
  local files = go:state():find_files()
  if not next(files.go or {}) then
    -- NOTE: only go files are relevant
    return tasks
  end

  -- NOTE: iterate only over the go files
  for _, entry in ipairs(files.go) do
    if entry:match ".*.go$" and is_main_file(entry) then
      local path = Path:new(entry)
      local root = Path:new(util.find_file_root(entry, { "go.mod" }))
      if root:joinpath("go.mod"):is_file() then
        --NOTE: if the FOUND file  is a go main file and has
        --a parent go.mod file, add a task for running the
        --project in the found file's directory.
        local cwd = path:parent():__tostring()
        path:make_relative(root:__tostring())
        local name = "Go project: " .. path:__tostring()
        table.insert(tasks, build_project_task(cwd, name))
      elseif entry == vim.api.nvim_buf_get_name(buf) then
        --NOTE: if the CURRENT file is a main go file
        --but there is no parent go.mod file, add a task
        --for only running the current file
        local cwd = vim.loop.cwd()
        path:make_relative(cwd)
        local name = "Run current Go file"
        table.insert(tasks, build_current_file_task(entry, cwd, name))
      end
    end
  end
  return tasks
end

build_project_task = function(cwd, name)
  local executable = env.get({ "GO", "EXECUTABLE" }, "go")
  local build_flags = env.get({ "GO", "RUN", "BUILD_FLAGS" }, {})
  local arguments = env.get({ "GO", "RUN", "ARGUMENTS" }, {})
  local xprog = env.get({ "GO", "RUN", "XPROG" }, false)
  local go_env = env.get({ "GO", "ENV" }, nil)

  local run_cmd = { executable, "run" }
  local build_cmd = { executable, "build" }

  local flags_string = get_opts_string(build_flags or {})
  if flags_string then
    table.insert(run_cmd, flags_string)
    table.insert(build_cmd, flags_string)
  end
  if xprog then
    table.insert(run_cmd, "-exec xprog")
  end
  table.insert(run_cmd, ".")
  local args_string = get_opts_string(arguments or {})
  if args_string then
    table.insert(run_cmd, args_string)
  end
  local cmd = {
    run = run_cmd,
    build = build_cmd,
  }
  if not setup.opts.enable_build_commands then
    cmd = run_cmd
  end
  return {
    name,
    cmd = cmd,
    env = go_env,
    cwd = cwd,
  }
end

build_current_file_task = function(package, cwd, name)
  local executable = env.get({ "GO", "EXECUTABLE" }, "go")
  local build_flags = env.get({ "GO", "RUN", "BUILD_FLAGS" }, {})
  local arguments = env.get({ "GO", "RUN", "ARGUMENTS" }, {})
  local xprog = env.get({ "GO", "RUN", "XPROG" }, false)
  local go_env = env.get({ "GO", "ENV" }, nil)

  local cmd = { executable, "run" }

  local flags_string = get_opts_string(build_flags or {})
  if flags_string then
    table.insert(cmd, flags_string)
  end
  if xprog then
    table.insert(cmd, "-exec xprog")
  end
  if package then
    table.insert(cmd, package)
  end
  local args_string = get_opts_string(arguments or {})
  if args_string then
    table.insert(cmd, args_string)
  end
  return {
    name,
    cmd = cmd,
    env = go_env,
    cwd = cwd,
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

--- Check whether the provided file contains both
--- the main package and the main function.
is_main_file = function(file)
  local ok, ok2 = pcall(function()
    local path = Path:new(file)
    if not path:is_file() then
      return false
    end

    local text = path:read()
    if type(text) ~= "string" then
      return false
    end

    -- TODO: handle any comments before the package definition ...
    -- maybe use treesitter nodes instead??
    text = text:gsub("\n", " ")
    local main_package_pattern = "^%s*package%s+main;?%s+.*func%s+main%s*%("

    local r = text:find(main_package_pattern)
    return r ~= nil
  end)
  return ok and ok2
end

return go
