local util = require "telescope._extensions.tasks.util"
local env = require "telescope._extensions.tasks.generators.env"
local Path = require "plenary.path"
local scan = require "plenary.scandir"

local go = {}

---Returns tasks for running a go project. If there is a go.mod
---file in one of the cwd's parent directories, tasks are created for all
---go files with main packages.
---If there is no go.mod file and the current file is a go file and
---has a main package, the task for running the current file is returned.
---
---go run [build flags] [-exec xprog] package [arguments...]
---
function go.gen(buf)
  local opts = {
    executable = env.get({ "GO", "EXECUTABLE" }, "go"),
    build_flags = env.get({ "GO", "RUN", "BUILD_FLAGS" }, {}),
    arguments = env.get({ "GO", "RUN", "ARGUMENTS" }, {}),
    xprog = env.get({ "GO", "RUN", "XPROG" }, false),
    go_env = env.get({ "GO", "ENV" }, nil),
    package = nil,
    cwd = nil,
    name = nil,
  }

  local tasks = {}
  local run_project_task, checked_files =
    go.run_current_project_generator(opts)

  if run_project_task and next(run_project_task) then
    tasks = run_project_task
  end

  local name = vim.api.nvim_buf_get_name(buf)
  if checked_files and checked_files[name] then
    return tasks
  end
  local run_cur_file_task = go.run_current_file_generator(buf, opts)
  if run_cur_file_task then
    table.insert(tasks, run_cur_file_task)
  end

  if next(tasks or {}) then
    return tasks
  end
  return nil
end

---Returns the run_current_file task only if the
---current filetype is 'go' and the current file contains
---the 'main' function.
---Otherwise returns nil.
function go.run_current_file_generator(buf, opts)
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  if filetype ~= "go" then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if go.file_is_main_package(name) then
    opts.package = name
    opts.name = "Run current Go file"
    return go.build_task_from_opts(opts)
  end
  return nil
end

---Returns nil if there is no go.mod in the file's parent directoires.
---If there is, returns a task for every file with the main function.
function go.run_current_project_generator(opts)
  local cwd = Path:new(util.find_parent_root { "go.mod" })
  if not (cwd:joinpath "go.mod"):is_file() then
    return nil
  end
  local tasks = {}
  local checked_files = {}

  for _, name in ipairs(scan.scan_dir(cwd:__tostring(), { hidden = false })) do
    local path = Path:new(name)
    checked_files[path:__tostring()] = true
    if
      name:match ".*.go$"
      and path:is_file()
      and go.file_is_main_package(name)
    then
      opts.cwd = path:parent():__tostring()
      path:make_relative(cwd:__tostring())
      opts.name = "Run Go project: " .. path:__tostring()
      opts.package = "."
      table.insert(tasks, go.build_task_from_opts(opts))
    end
  end
  if next(tasks or {}) then
    return tasks, checked_files
  end
  return nil, checked_files
end

function go.build_task_from_opts(opts)
  local cmd = {
    opts.executable,
    "run",
  }
  local flags_string = go.get_opts_string(opts.build_flags or {})
  if flags_string then
    table.insert(cmd, flags_string)
  end
  if opts.xprog then
    table.insert(cmd, "-exec xprog")
  end
  table.insert(cmd, opts.package)
  local args_string = go.get_opts_string(opts.arguments or {})
  if args_string then
    table.insert(cmd, args_string)
  end
  return {
    opts.name,
    cmd = cmd,
    env = opts.env,
    cwd = opts.cwd,
  }
end

function go.get_opts_string(opts)
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

function go.file_is_main_package(file)
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
    text = text:gsub("\n", " ")
    local main_package_pattern = "^%s*package%s+main;?%s+"

    local r = text:find(main_package_pattern)
    return r ~= nil
  end)
  return ok and ok2
end

return go.gen
