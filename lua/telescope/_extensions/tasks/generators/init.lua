local enum = require "telescope._extensions.tasks.enum"
local runner = require "telescope._extensions.tasks.generators.runner"
local current = require "telescope._extensions.tasks.generators.current"
local default = require "telescope._extensions.tasks.generators.default"

local generators = {}

---Add a custom generator. The generator will run on every BufEnter
---Or DirChanged event in the buffers with `buftype`="".
---
---Generated tasks will be cached based on the buffer number and cwd, so
---they won't be run multiple times unless one of those has been changed.
---Additional options may be provided.
---
---@param generator table|function: A generator.
---The generator may be just a generator function or a table with keys
---  - `generator` (function) The generator function.
---  - `opts` (Generator_opts|nil) The generator conditions. This is a table with fields:
---       - `filetypes`: A table of filetypes for the generator to run in.
---       - `patterns`: A table of lua patterns. Generator will only be run when the filename
---        matches one of the patterns.
---       - `ignore_patterns`: a table of lua patterns. Generator will only be run when the filename
---        does not match any of the patterns.
function generators.add(generator)
  local ok, added = pcall(current.add, generator)
  if not ok and type(added) == "string" then
    vim.notify(added, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
  else
    runner.run { added }
  end
end

---Add a batch of generators at once. This is useful when you want to
---Add multiple generators at once, so you can avoid calling `generators.add`
---multiple times.
---
---@param generators_batch table: A table of generators.
---Each generator is the same as the parameter for the `generators.add(generator)` function.
function generators.add_batch(generators_batch)
  local ok, added = pcall(current.add_batch, generators_batch)
  if not ok and type(added) == "string" then
    vim.notify(added, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
  else
    runner.run(added)
  end
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

return generators
