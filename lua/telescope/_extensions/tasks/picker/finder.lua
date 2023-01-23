local finders = require "telescope.finders"
local enum = require "telescope._extensions.tasks.enum"
local entry_display = require "telescope.pickers.entry_display"
local executor = require "telescope._extensions.tasks.executor"
local runner = require "telescope._extensions.tasks.generators.runner"

local finder = {}

local get_task_display

---Create a telescope finder for the currently available tasks.
---
---@param buf number?: Buffer from where the picker was opened
---(current buffer by default)
---@param exit_on_no_results boolean?: Return nil and warn if no results found.
---@return table?: a telescope finder
function finder.available_tasks_finder(buf, exit_on_no_results)
  local tasks = vim.tbl_values(runner.run(buf) or {})
  if exit_on_no_results and not next(tasks) then
    vim.notify("There xare no available tasks", vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return nil
  end

  return finders.new_table {
    results = tasks,
    entry_maker = function(entry)
      return {
        value = entry,
        ordinal = entry.name,
        display = function(entry2)
          return get_task_display(entry2.value)
        end,
      }
    end,
  }
end

get_task_display = function(task)
  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 8 },
      { remaining = true },
    },
  }
  if executor.is_running(task.name) then
    return displayer {
      { "Running", "Function" },
      task.name,
    }
  end
  local buf = executor.get_task_output_buf(task.name)
  if buf ~= nil and vim.api.nvim_buf_is_valid(buf) then
    return displayer {
      { "Output", "Comment" },
      task.name,
    }
  end
  return displayer {
    { "" },
    task.name,
  }
end

return finder
