local enum = require "telescope._extensions.tasks.enum"
local executor = require "telescope._extensions.tasks.executor"

local should_run_generators

local runner = {}

local generators_updated = false
local current_generators = {}
local cache = {}

---Runs all the available generators.
---@return table: The found tasks
function runner.run(buf)
  local ok, tasks = pcall(function()
    if not next(current_generators or {}) then
      return {}
    end

    if type(buf) ~= "number" or not vim.api.nvim_buf_is_valid(buf) then
      buf = vim.api.nvim_get_current_buf()
    end
    if not should_run_generators(buf) then
      return {}
    end

    local cwd = vim.loop.cwd()

    local found_tasks = {}
    if not generators_updated and cache[buf] and cache[buf].cwd == cwd then
      found_tasks = cache[buf].tasks or {}
    else
      for _, generator in ipairs(generators or current_generators or {}) do
        if generator:available() then
          found_tasks =
            vim.tbl_extend("force", found_tasks, generator:run() or {})
        end
      end
      cache[buf] = {
        cwd = cwd,
        tasks = found_tasks,
      }
    end

    generators_updated = false

    found_tasks =
      vim.tbl_extend("force", found_tasks, executor.get_running_tasks() or {})

    return found_tasks
  end)
  if not ok and type(tasks) == "string" then
    vim.notify(tasks, vim.log.levels.ERROR, {
      title = enum.TITLE,
    })
    return {}
  end
  return tasks or {}
end

function runner.add_generator(generator)
  table.insert(current_generators, generator)
  generators_updated = true
end

---Checks whether the generators should be run in the provided buffer.
---@param buf number
---@return boolean: Whether the generators should be run
should_run_generators = function(buf)
  local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
  return buftype:len() == 0
end

return runner
