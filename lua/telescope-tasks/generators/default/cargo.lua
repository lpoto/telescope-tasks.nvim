
local setup = require("telescope-tasks.setup")
local enum = require("telescope-tasks.enum")
local Path = require("plenary.path")
local Default_generator = require("telescope-tasks.model.default_generator")
local State = require("telescope-tasks.model.state")

---cargo run [options] [-- args]
---
---NOTE: this returns only tasks for running rust with cargo
local cargo = Default_generator:new({
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
})

local run_cargo_project
local check_cargo_files
local check_current_binary

function cargo.generator(buf)
  if not cargo:state() then
    return {}
  end
  local files = (cargo:state():find_files(5) or {}).by_name
  local entries = (files or {})["Cargo.toml"]
  local checked_targets = {}
  local tasks = check_cargo_files(entries, checked_targets)
  local current_binary = check_current_binary(buf, checked_targets)
  if type(current_binary) == "table" then
    table.insert(tasks, current_binary)
  end
  return tasks
end

check_current_binary = function(buf, checked_targets)
  local filtype = vim.api.nvim_buf_get_option(buf, "filetype")
  if filtype ~= "rust" then
    return
  end
  local filename = vim.api.nvim_buf_get_name(buf)
  local target = filename:match("src/bin/(.-)%.rs")
  if not target or checked_targets[target] then
    return
  end
  local path = Path:new(filename)
  local cwd = path:parent():parent():parent()
  local cargo_toml = cwd:joinpath("Cargo.toml")
  if not cargo_toml:is_file() then
    return
  end

  local env = setup.opts.env.cargo
  local binary = setup.opts.binary.cargo or "cargo"

  local t = {
    "Run current Cargo binary",
    cmd = { binary, "run", "--bin", target },
    filename = filename,
    priority = enum.PRIORITY.MEDIUM + 5,
    keywords = {
      "cargo",
      "current_binary",
      target,
      filename,
    },
  }
  if type(env) == "table" and next(env) then
    t.env = env
  end
  return t
end

check_cargo_files = function(entries, checked_targets)
  if not entries or not next(entries) then
    return {}
  end
  local tasks = {}
  for _, entry in ipairs(entries) do
    local path = Path:new(entry)
    local full_path = path:__tostring()
    local cwd = path:parent():__tostring()
    for _, v in
    ipairs(run_cargo_project(cwd, full_path, checked_targets) or {})
    do
      table.insert(tasks, v)
    end
  end
  return tasks
end

run_cargo_project = function(cwd, full_path, checked_targets)
  local path = Path:new(full_path)
  local lines = path:readlines()
  path:normalize()
  local next_name = false
  local targets = {}
  for _, l in ipairs(lines) do
    local x = l:match("^%s*%[(.-)%]%s*$")
    if x and x == "package" or x == "[bin]" then
      next_name = true
    elseif x then
      next_name = false
    end
    if next_name then
      local t = l:match('^%s*name%s*=%s*"(.-)"%s*$')
      if not t then
        t = l:match("^%s*name%s*=%s*'(.-)'%s*$")
      end
      if t then
        targets[t] = true
      end
    end
  end
  local t = {}
  local env = setup.opts.env.cargo

  local binary = setup.opts.binary.cargo or "cargo"

  for target, _ in pairs(targets) do
    if not checked_targets[target] then
      checked_targets[target] = true
      local cmd = { binary, "run", "--bin", target }
      local task = {
        name = "Cargo " .. target .. ": " .. path:__tostring(),
        cmd = cmd,
        cwd = cwd,
        filename = full_path,
        priority = enum.PRIORITY.LOW + 5,
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
  end

  return t
end

function cargo.healthcheck()
  local binary = setup.opts.binary.cargo or "cargo"
  if vim.fn.executable(binary) == 0 then
    vim.health.warn("Cargo binary '" .. binary .. "' is not executable", {
      "Install 'cargo' or set a different binary in setup",
    })
  else
    vim.health.ok("'" .. binary .. "' is executable")
  end
end

function cargo.on_load()
  State.register_file_names({ "Cargo.toml" })
end

return cargo
