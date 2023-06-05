local util = require "telescope._extensions.tasks.util"
local Path = require "plenary.path"
local Default_generator =
  require "telescope._extensions.tasks.model.default_generator"

---cargo run [options] [-- args]
---
---NOTE: this returns only tasks for running rust with cargo
local cargo = Default_generator:new {
  errorformat = [[%Eerror: %\%%(aborting %\|could not compile%\)%\@!%m,]]
    .. [[%Eerror[E%n]: %m,]]
    .. [[%Inote: %m,]]
    .. [[%Wwarning: %\%%(%.%# warning%\)%\@!%m,]]
    .. [[%C %#--> %f:%l:%c,]]
    .. [[%E  left:%m,%C right:%m %f:%l:%c,%Z,]]
    .. [[%.%#panicked at \'%m\'\, %f:%l:%c]],
  opts = {
    name = "Default Cargo Generator",
    experimental = true,
  },
}

local run_cargo_project
local check_cargo_files

function cargo.generator()
  if not cargo:state() then
    return {}
  end
  local parent_cargo_exists = util.parent_dir_includes { "Cargo.toml" }
  local parent_cargo_toml = nil
  if parent_cargo_exists then
    parent_cargo_toml =
      Path:new(util.find_current_file_root { "Cargo.toml" }, "Cargo.toml")
        :__tostring()
  end
  local files = (cargo:state():find_files() or {}).by_name
  local entries = (files or {})["Cargo.toml"]

  local tasks = check_cargo_files(entries)
  if
    parent_cargo_toml
    and (
      type(entries) ~= "table"
      or not vim.tbl_contains(entries, parent_cargo_toml)
    )
  then
    local tasks2 = check_cargo_files { parent_cargo_toml }
    if tasks2 then
      for _, task in ipairs(tasks2) do
        table.insert(tasks, task)
      end
    end
  end
  return tasks
end

check_cargo_files = function(entries)
  if not entries or not next(entries) then
    return {}
  end
  local tasks = {}
  for _, entry in ipairs(entries) do
    local path = Path:new(entry)
    local full_path = path:__tostring()
    local cwd = path:parent():__tostring()
    for _, v in ipairs(run_cargo_project(cwd, full_path) or {}) do
      table.insert(tasks, v)
    end
  end
  return tasks
end

run_cargo_project = function(cwd, full_path)
  local path = Path:new(full_path)
  local lines = path:readlines()
  path:normalize()
  local next_name = false
  local targets = {}
  for _, l in ipairs(lines) do
    local x = l:match "^%s*%[(.-)%]%s*$"
    if x and x == "package" or x == "[bin]" then
      next_name = true
    elseif x then
      next_name = false
    end
    if next_name then
      local t = l:match '^%s*name%s*=%s*"(.-)"%s*$'
      if not t then
        t = l:match "^%s*name%s*=%s*'(.-)'%s*$"
      end
      if t then
        targets[t] = true
      end
    end
  end
  local t = {}
  local env = util.get_env "cargo"

  local binary = util.get_binary "cargo" or "cargo"

  for target, _ in pairs(targets) do
    local cmd = { binary, "run", "--bin", target }
    local task = {
      name = "Cargo " .. target .. ": " .. path:__tostring(),
      cmd = cmd,
      cwd = cwd,
      filename = full_path,
      keywords = {
        "cargo",
        target,
        full_path,
      },
    }
    if type(env) == "table" and next(env) then
      task.env = env
    end
    table.insert(t, task)
  end

  return t
end

function cargo.healthcheck()
  local binary = util.get_binary "cargo" or "cargo"
  if vim.fn.executable(binary) == 0 then
    vim.health.warn("Cargo binary '" .. binary .. "' is not executable", {
      "Install 'cargo' or set a different binary with vim.g.telescope_tasks = { binaries = { cargo=<new-binary> }}",
    })
  else
    vim.health.ok("'" .. binary .. "' is executable")
  end
end

return cargo
