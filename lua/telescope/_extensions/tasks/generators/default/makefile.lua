local Default = require "telescope._extensions.tasks.model.default_generator"
local Path = require "plenary.path"

local makefile = Default:new {
  opts = {
    name = "Default Makefile targets Generator",
    experimental = true,
  },
}

local get_task

function makefile.generator()
  local files = (makefile:state():find_files() or {}).by_name
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

  local t = {
    relative_path .. ": " .. target,
    filename = filename,
    cmd = { "make", target },
    cwd = cwd,
    __meta = {
      name = "makefile_task_" .. target .. "_" .. filename
        :gsub("/", "_")
        :gsub("\\", "-"),
    },
  }
  if type(vim.g.MAKEFILE_ENV) == "table" and next(vim.g.MAKEFILE_ENV) then
    t.env = vim.g.MAKEFILE_ENV
  end
  return t
end

return makefile
