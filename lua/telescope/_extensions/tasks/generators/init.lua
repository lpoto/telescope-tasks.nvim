local enum = require "telescope._extensions.tasks.enum"
local runner = require "telescope._extensions.tasks.generators.runner"
local Generator = require "telescope._extensions.tasks.model.generator"
local default = require "telescope._extensions.tasks.generators.default"

local generators = {}
local add_batch

---Add a custom generator. The generator will run on every BufEnter
---Or DirChanged event in the buffers with `buftype`="".
---
---Generated tasks will be cached based on the buffer number and cwd, so
---they won't be run multiple times unless one of those has been changed.
---Additional options may be provided.
---
---@param generator Generator|function: A generator.
---The generator may be just a generator function or a table with keys
---  - `generator` (function) The generator function.
---  - `opts` (Generator_opts|nil) The generator conditions.
function generators.add(generator)
  generators.add_batch { generator }
end

---Add a batch of generators at once. This is useful when you want to
---Add multiple generators at once, so you can avoid calling `generators.add`
---multiple times.
---
---@param generators_batch table: A table of generators.
---Each generator is the same as the parameter for the `generators.add(generator)` function.
function generators.add_batch(generators_batch)
  add_batch(generators_batch)
end

---A table containing the functions, each returning the
---Generator config for a default generator.
generators.default = default

---Enable all default generators.
function generators.enable_default()
  local defaults = {}
  for _, generator in pairs(default) do
    table.insert(defaults, generator())
  end
  generators.add_batch(defaults)
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
