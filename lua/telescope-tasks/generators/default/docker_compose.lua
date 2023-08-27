local Default = require("telescope-tasks.model.default_generator")
local enum = require("telescope-tasks.enum")
local Path = require("plenary.path")
local State = require("telescope-tasks.model.state")
local setup = require("telescope-tasks.setup")

local docker_compose = Default:new({
  opts = {
    name = "Default docker-compose Generator",
    experimental = true,
  },
})

local get_task

function docker_compose.generator()
  local files = (docker_compose:state():find_files(5) or {}).by_extension
  if not next(files or {}) then
    return {}
  end
  local tasks = {}
  for _, v in ipairs(files["yml"] or {}) do
    local task = get_task(v)
    if type(task) == "table" then
      table.insert(tasks, task)
    end
  end
  for _, v in ipairs(files["yaml"] or {}) do
    local task = get_task(v)
    if type(task) == "table" then
      table.insert(tasks, task)
    end
  end
  return tasks
end

local is_compose_file
function get_task(yaml_file)
  if not is_compose_file(yaml_file) then
    return nil
  end
  local path = Path:new(yaml_file)
  local cwd = path:parent():__tostring()
  local filename = path:__tostring()
  path:normalize(vim.fn.getcwd())

  local binary = setup.opts.binary["docker-compose"]
  if not binary then
    binary = setup.opts.binary["docker_compose"]
  end
  if not binary then
    if vim.fn.executable("docker-compose") == 1 then
      binary = "docker-compose"
    else
      binary = "docker compose"
    end
  end

  local cmd = {
    binary,
    "-f",
    filename,
    "up",
    "--build",
  }

  local tasks = {}

  local t = {
    "Docker compose: " .. path:__tostring(),
    filename = filename,
    cmd = cmd,
    cwd = cwd,
    priority = enum.PRIORITY.LOW + 2,
    keywords = {
      "docker-compose",
      filename,
    },
  }
  local env = setup.opts.env["docker-compose"]
  if type(env) == "table" and next(env) then
    t.env = env
  else
    env = setup.opts.env["docker_compose"]
    if type(env) == "table" and next(env) then
      t.env = env
    end
  end
  table.insert(tasks, t)
  return t
end

function is_compose_file(file)
  local path = Path:new(file)
  if not path:is_file() then
    return false
  end
  local lines = path:readlines()
  local patterns_found = 0
  for _, line in ipairs(lines) do
    if patterns_found >= 2 then
      return true
    end
    if patterns_found == 0 and line:match("^%s*services:%s*") then
      patterns_found = 1
    elseif patterns_found > 0 then
      if line:match("^%s*image:") or line:match("^%s*build:") then
        patterns_found = patterns_found + 1
      end
    end
  end
  return patterns_found >= 2
end

function docker_compose.on_load()
  State.register_file_extensions({ "yml", "yaml" })
end

return docker_compose
