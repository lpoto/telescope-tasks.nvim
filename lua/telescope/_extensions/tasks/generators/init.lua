local enum = require "telescope._extensions.tasks.enum"
local runner = require "telescope._extensions.tasks.generators.runner"
local cache = require "telescope._extensions.tasks.generators.cache"
local current = require "telescope._extensions.tasks.generators.current"

local generators = {}

---Add a custom generator. The generator will run on every BufEnter
---Or DirChanged event in the buffers with `buftype`="".
---
---Generated tasks will be cached based on the buffer number and cwd, so
---they won't be run multiple times unless one of those has been changed.
---Additional options may be provided.
---
---@param generator function: A generator function that receives a
---buffer number as input and returns a table of tasks or nil.
---@param opts Generator_opts?: Optional generator conditions:
---  `filetypes`: A table of filetypes for the generator to run in.
---  `patterns`: A table of lua patterns. Generator will only be run when the filename
---   matches one of the patterns.
---  `ignore_patterns`: a table of lua patterns. Generator will only be run when the filename
---   does not match any of the patterns.
function generators.add(generator, opts)
  local ok, e = pcall(current.add_custom, generator, opts)
  if not ok and type(e) == "string" then
    vim.notify(e, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
  elseif cache.is_empty() then
    runner.run()
  end
end

---Add a batch of generators at once. This is useful when you want to
---Add multiple generators at once, so you can avoid calling `generators.add`
---multiple times.
---
---@param generators_batch table: A table of generator functions and options.
---The elements should be tables with the function on index 1 and opts on index 2.
---These functions and options are the same as in `generators.add(generator, opts)`
function generators.add_batch(generators_batch)
  local ok, e = pcall(current.add_batch, generators_batch)
  if not ok and type(e) == "string" then
    vim.notify(e, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
  elseif cache.is_empty() then
    runner.run()
  end
end

return generators
