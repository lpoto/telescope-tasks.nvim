local runner = require "telescope._extensions.tasks.generators.runner"
local enum = require "telescope._extensions.tasks.enum"
local Generator = require "telescope._extensions.tasks.model.generator"

local custom = {}

---Add custom generators. These generators will run before the
---tasks prompt is opened, unless the current buftype is not "".
---
---@param ... Generator|function: One or more generators,
---where each generator may be just a generator function or a table with keys:
---  - `generator` (function) The generator function.
---  - `opts` (Generator_opts|nil) The generator conditions.
function custom.add(...)
  local generators = {}
  for _, gen in ipairs { select(1, ...) } do
    local ok, e = pcall(function()
      local generator = Generator:new(gen)
      table.insert(generators, generator)
    end)
    if not ok and type(e) == "string" then
      vim.notify(e, vim.log.levels.WARN, {
        title = enum.TITLE,
      })
    end
  end

  runner.add_generators(generators)
end

return custom