local util = require "telescope._extensions.tasks.util"
local Path = require "plenary.path"
local scan = require "plenary.scandir"
local Default = require "telescope._extensions.tasks.model.default_generator"

---Generate tasks for running go projects in subdirectories,
---or a task for running the current file if there is no
---go.mod files.
---
---go run [build flags] [-exec xprog] package [arguments...]
---
local go = Default:new {
  errorformat = "%f:%l.%c-%[%^:]%#:\\ %m,%f:%l:%c:\\ %m",
  opts = {
    name = "Default Go Generator",
    experimental = true,
  },
}

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

  local checked = {}

  local files = (go:state():find_files() or {}).by_extension
  local entries = (files or {}).go
  local tasks = check_go_files(entries, buf, checked) or {}

  local parent_go_mod_exists = util.parent_dir_includes { "go.mod" }
  if not parent_go_mod_exists then
    return tasks
  end
  local parent_go_mod_dir = util.find_current_file_root { "go.mod" }

  if checked[parent_go_mod_dir] then
    return tasks
  end
  local found = false
  scan.scan_dir(parent_go_mod_dir, {
    add_dirs = true,
    depth = 1,
    on_insert = function(entry)
      if not found and entry:match ".*.go$" and is_main_file(entry) then
        local path = Path:new(entry)
        local cwd = path:parent():__tostring()
        local full_path = path:__tostring()
        path:normalize(vim.fn.getcwd())
        checked[cwd] = true
        local name = "Go project: " .. path:__tostring()
        table.insert(tasks, run_project_task(cwd, name, full_path))
      end
    end,
  })
  return tasks
end

check_go_files = function(entries, buf, checked)
  if type(entries) ~= "table" or not next(entries) then
    return
  end
  local tasks = {}
  for _, entry in ipairs(entries) do
    if entry:match ".*.go$" and is_main_file(entry) then
      local path = Path:new(entry)
      local root = Path:new(util.find_file_root(entry, { "go.mod" }))
      if root:joinpath("go.mod"):is_file() then
        --NOTE: if the FOUND file  is a go main file and has
        --a parent go.mod file, add a task for running the
        --project in the found file's directory.
        local cwd = path:parent():__tostring()
        checked[cwd] = true
        local full_path = path:__tostring()
        path:normalize(vim.fn.getcwd())
        local name = "Go project: " .. path:__tostring()
        table.insert(tasks, run_project_task(cwd, name, full_path))
      elseif entry == vim.api.nvim_buf_get_name(buf) then
        --NOTE: if the CURRENT file is a main go file
        --but there is no parent go.mod file, add a task
        --for only running the current file
        local cwd = vim.loop.cwd()
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
  local binary = util.get_binary "go" or "go"
  local cmd = { binary, "run", "." }

  local t = {
    name,
    cmd = cmd,
    cwd = cwd,
    filename = full_path,
    keywords = {
      "go",
      "project",
      full_path,
    },
  }
  local env = util.get_env "go"
  if type(env) == "table" and next(env) then
    t.env = env
  end
  return t
end

run_current_file_task = function(package, cwd, name, filename)
  local binary = util.get_binary "go" or "go"
  local cmd = { binary, "run", package }

  local t = {
    name,
    cmd = cmd,
    cwd = cwd,
    filename = filename,
    keywords = {
      "go",
      "file",
      package,
    },
  }
  local env = util.get_env "go"
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
  local binary = util.get_binary "go" or "go"
  if vim.fn.executable(binary) == 0 then
    vim.health.warn("Go binary '" .. binary .. "' is not executable", {
      "Install 'go' or set a different binary with vim.g.telescope_tasks = { binaries = { go=<new-binary> }}",
    })
  else
    vim.health.ok("'" .. binary .. "' is executable")
  end
end

return go
