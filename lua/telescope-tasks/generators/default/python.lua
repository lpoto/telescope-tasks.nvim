local Default = require "telescope-tasks.model.default_generator"
local util = require "telescope-tasks.util"
local enum = require "telescope-tasks.enum"
local Path = require "plenary.path"
local State = require "telescope-tasks.model.state"

---Add a task for running the current python file.
local python = Default:new {
  errorformat = '%C\\ %.%#,%A\\ \\ File\\ "%f"\\,'
    .. "\\ line\\ %l%.%#,%Z%[%^\\ ]%\\@=%m",
  opts = {
    name = "Default Python Generator",
    experimental = true,
  },
}

local get_binary
local check_main_files

function python.generator(buf)
  local files = (python:state():find_files(5) or {}).by_name
  local entries = (files or {})["__main__.py"]
  local checked = {}
  local tasks = check_main_files(entries, checked)
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  local name = vim.api.nvim_buf_get_name(buf)
  if filetype ~= "python" or checked[name] then
    return tasks
  end
  if not tasks then
    tasks = {}
  end

  local t = {
    "Run current Python file",
    cmd = { get_binary(), name },
    filename = name,
    priority = enum.PRIORITY.MEDIUM,
    keywords = {
      "python",
      "file",
      name,
    },
  }
  local env = util.get_env "python"
  if type(env) == "table" and next(env) then
    t.env = env
  end
  table.insert(tasks, t)
  return tasks
end

check_main_files = function(entries, checked)
  if type(entries) ~= "table" or not next(entries) then
    return {}
  end
  local env = util.get_env "python"
  local tasks = {}
  for _, entry in ipairs(entries) do
    local path = Path:new(entry)
    local cwd = path:parent():__tostring()
    local full_path = path:__tostring()
    checked[full_path] = true
    path:normalize(vim.fn.getcwd())

    local t = {
      "Python project: " .. path:__tostring(),
      cmd = { "python", "." },
      cwd = cwd,
      filename = full_path,
      priority = enum.PRIORITY.LOW,
      keywords = {
        "python",
        "project",
        full_path,
      },
    }
    if type(env) == "table" and next(env) then
      t.env = env
    end
    table.insert(tasks, t)
  end
  return tasks
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

function python.on_load()
  State.register_file_names { "__main__.py" }
end

return python
