local enum = require "telescope._extensions.tasks.enum"
local runner = require "telescope._extensions.tasks.generators.runner"
local Generator = require "telescope._extensions.tasks.model.generator"
local default = require "telescope._extensions.tasks.generators.default"

local generators = {}
local add_batch

---Add custom generators. These generators will run before the
---tasks prompt is opened, unless the current buftype is not "".
---
---@param ... Generator|function: One or more generators,
---where each generator may be just a generator function or a table with keys:
---  - `generator` (function) The generator function.
---  - `opts` (Generator_opts|nil) The generator conditions.
function generators.add(...)
  add_batch { select(1, ...) }
end

---A table containing the functions, each returning the
---Generator config for a default generator.
generators.default = default

---Enable all default generators.
function generators.enable_all_default()
  generators.add(default.all())
end

add_batch = function(generators_batch)
  local ok, err = pcall(function()
    assert(
      type(generators_batch) == "table",
      "A batch of generators must be a table"
    )
    for _, generator in ipairs(generators_batch) do
      runner.add_generator(Generator:new(generator))
    end
  end)
  if not ok and type(err) == "string" then
    pcall(vim.notify, err, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
  end
end

return generators
