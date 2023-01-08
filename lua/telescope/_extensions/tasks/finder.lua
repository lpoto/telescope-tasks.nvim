local finders = require "telescope.finders"
local Task = require "telescope._extensions.tasks.model.task"
local entry_display = require "telescope.pickers.entry_display"
local executor = require "telescope._extensions.tasks.executor"

local finder = {}

local get_task_display

---Create a telescope finder for the currently available tasks.
---
---@param prev_buf number|nil: The buffer from which the picker was opened
---@return table: a telescope finder
function finder.available_tasks_finder(prev_buf)
  local tasks, _ = Task.__available_tasks(prev_buf)
  tasks = tasks or {}

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
