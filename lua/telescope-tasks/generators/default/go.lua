local util = require("telescope-tasks.util")
local setup = require("telescope-tasks.setup")
local enum = require("telescope-tasks.enum")
local Path = require("plenary.path")
local Default = require("telescope-tasks.model.default_generator")
local State = require("telescope-tasks.model.state")

---Generate tasks for running go projects in subdirectories,
---or a task for running the current file if there is no
---go.mod files.
---
---go run [build flags] [-exec xprog] package [arguments...]
---
local go = Default:new({
  errorformat = "%f:%l.%c-%[%^:]%#:\\ %m,%f:%l:%c:\\ %m",
  opts = {
    name = "Default Go Generator",
    experimental = true,
  },
})

local is_main_file
local run_current_file_task
local run_project_task
local check_go_files

--- Build tasks by finding main go files in the subdirectories.
--- If there are go.mod files, return tasks for running projects
--- otherise returns just a task for running the current go file.
function go.generator(buf)
  if not go:state() then
    return {}
  end
  buf = buf or vim.api.nvim_get_current_buf()

  local files = (go:state():find_files(5) or {}).by_extension
  local entries = (files or {}).go
  return check_go_files(entries, buf) or {}
end

check_go_files = function(entries, buf)
  if type(entries) ~= "table" or not next(entries) then
    return
  end
  local tasks = {}
  for _, entry in ipairs(entries) do
    if entry:match(".*.go$") and is_main_file(entry) then
      local path = Path:new(entry)
      local root = Path:new(util.find_file_root(entry, { "go.mod" }))
      if root:joinpath("go.mod"):is_file() then
        --NOTE: if the FOUND file  is a go main file and has
        --a parent go.mod file, add a task for running the
        --project in the found file's directory.
        local cwd = path:parent():__tostring()
        local full_path = path:__tostring()
        path:normalize(vim.fn.getcwd())
        local name = "Go project: " .. path:__tostring()
        table.insert(tasks, run_project_task(cwd, name, full_path))
      elseif entry == vim.api.nvim_buf_get_name(buf) then
        --NOTE: if the CURRENT file is a main go file
        --but there is no parent go.mod file, add a task
        --for only running the current file
        local cwd = vim.fn.getcwd()
        local name = "Run current Go file"
        table.insert(
          tasks,
          run_current_file_task(
            entry,
            cwd,
            name,
            vim.api.nvim_buf_get_name(buf)
          )
        )
      end
    end
  end
  return tasks
end

run_project_task = function(cwd, name, full_path)
  local binary = setup.opts.binary.go or "go"
  local cmd = { binary, "run", "." }

  local t = {
    name,
    cmd = cmd,
    cwd = cwd,
    filename = full_path,
    priority = enum.PRIORITY.LOW + 6,
    keywords = {
      "go",
      "project",
      full_path,
    },
  }
  local env = setup.opts.env.go
  if type(env) == "table" and next(env) then
    t.env = env
  end
  return t
end

run_current_file_task = function(package, cwd, name, filename)
  local binary = setup.opts.binary.go or "go"
  local cmd = { binary, "run", package }

  local t = {
    name,
    cmd = cmd,
    cwd = cwd,
    filename = filename,
    priority = enum.PRIORITY.MEDIUM + 6,
    keywords = {
      "go",
      "file",
      package,
    },
  }
  local env = setup.opts.env.go
  if type(env) == "table" and next(env) then
    t.env = env
  end
  return t
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

function go.healthcheck()
  local binary = setup.opts.binary.go or "go"
  if vim.fn.executable(binary) == 0 then
    vim.health.warn("Go binary '" .. binary .. "' is not executable", {
      "Install 'go' or set a different binary with in setup",
    })
  else
    vim.health.ok("'" .. binary .. "' is executable")
  end
end

function go.on_load()
  State.register_file_names({ "go.mod" })
  State.register_file_extensions({ "go" })
end

return go
