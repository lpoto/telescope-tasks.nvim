local runner = require "telescope-tasks.generators.runner"
local util = require "telescope-tasks.util"
local Generator = require "telescope-tasks.model.generator"

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
      util.warn(e)
    end
  end

  runner.add_generators(generators)
end

return custom
