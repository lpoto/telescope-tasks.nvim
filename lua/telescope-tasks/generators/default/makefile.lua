local Default = require "telescope-tasks.model.default_generator"
local enum = require "telescope-tasks.enum"
local Path = require "plenary.path"
local State = require "telescope-tasks.model.state"
local util = require "telescope-tasks.util"

local makefile = Default:new {
  opts = {
    name = "Default Makefile targets Generator",
    experimental = true,
  },
}

local get_task

function makefile.generator()
  local files = (makefile:state():find_files(5) or {}).by_name
  if not next(files or {}) then
    return {}
  end
  local tasks = {}

  for _, n in ipairs { "makefile", "Makefile" } do
    for _, m in ipairs(files[n] or {}) do
      m = Path.new(m)
      local ok, lines = pcall(m.readlines, m)
      if ok then
        for _, line in ipairs(lines) do
          if not line:match "^%s*#" and line:match "^%w+%:" then
            local target = line:match "^%w+"
            table.insert(tasks, get_task(m, target))
          end
        end
      end
    end
  end
  return tasks
end

function get_task(path, target)
  local relative_path = path:make_relative(vim.fn.getcwd())
  local cwd = path:parent():__tostring()
  local filename = path:__tostring()
  local binary = util.get_binary "make" or "make"

  local t = {
    relative_path .. ": " .. target,
    filename = filename,
    cmd = { binary, target },
    cwd = cwd,
    priority = enum.PRIORITY.ZERO,
    keywords = {
      "makefile",
      filename,
      target,
    },
  }
  local env = util.get_env "makefile"
  if type(env) == "table" and next(env) then
    t.env = env
  end
  return t
end

function makefile.healthcheck()
  local binary = util.get_binary "make" or "make"
  if vim.fn.executable(binary) == 0 then
    vim.health.warn("Make binary '" .. binary .. "' is not executable", {
      "Install 'make' or set a different binary with vim.g.telescope_tasks = { binaries = { make=<new-binary> }}",
    })
  else
    vim.health.ok("'" .. binary .. "' is executable")
  end
end

function makefile.on_load()
  State.register_file_names { "makefile", "Makefile" }
end

return makefile
