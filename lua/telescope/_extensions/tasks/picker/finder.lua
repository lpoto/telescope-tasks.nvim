local finders = require "telescope.finders"
local util = require "telescope._extensions.tasks.util"
local entry_display = require "telescope.pickers.entry_display"
local executor = require "telescope._extensions.tasks.executor"
local runner = require "telescope._extensions.tasks.generators.runner"

local finder = {}

local get_task_display
local order_tasks
local tasks = {}

---Create a telescope finder for the currently available tasks.
---
---@param buf number?: Buffer from where the picker was opened
---(current buffer by default)
---@param exit_on_no_results boolean?: Return nil and warn if no results found.
---@param sort boolean?: Sort the results by timestamp
---@param find_tasks boolean?: Default = true
---@return table?: a telescope finder
function finder.available_tasks_finder(
  buf,
  exit_on_no_results,
  sort,
  find_tasks
)
  if find_tasks == nil then
    find_tasks = true
  end
  if find_tasks then
    tasks = runner.run(buf) or {}
    if exit_on_no_results and not next(tasks) then
      util.warn "There are no available tasks"
      return nil
    end
    tasks = order_tasks(tasks, sort)
  end

  return finders.new_table {
    results = tasks,
    entry_maker = function(entry)
      return {
        value = entry,
        ordinal = entry.name,
        filename = entry.filename,
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

local task_names = {}
local function get_tasks_ordering(tasks, new)
  if not new and next(task_names) then
    return task_names
  end
  task_names = {}
  for _, task in pairs(tasks) do
    table.insert(task_names, task.name)
  end
  table.sort(task_names, function(a, b)
    local a_running = executor.is_running(a)
    local b_running = executor.is_running(b)
    if a_running and not b_running then
      return true
    elseif not a_running and b_running then
      return false
    end
    local output_buf_a = executor.get_task_output_buf(a)
    local output_buf_b = executor.get_task_output_buf(b)
    if output_buf_a ~= nil and output_buf_b == nil then
      return true
    elseif output_buf_a == nil and output_buf_b ~= nil then
      return false
    end
    local a_timestamp = executor.get_task_latest_timestamp(a)
    local b_timestamp = executor.get_task_latest_timestamp(b)
    if a_timestamp ~= nil and b_timestamp == nil then
      return true
    elseif a_timestamp == nil and b_timestamp ~= nil then
      return false
    elseif a_timestamp == nil and b_timestamp == nil then
      return a < b
    end
    return a_timestamp > b_timestamp
  end)
  return task_names
end

function order_tasks(tasks, regen_ordering)
  local new_tasks = {}
  local inserted = {}
  local ordering = get_tasks_ordering(tasks, regen_ordering) or {}
  for _, name in ipairs(ordering) do
    inserted[name] = true
    if tasks[name] then
      table.insert(new_tasks, tasks[name])
    end
  end
  for name, task in pairs(tasks) do
    if not inserted[name] then
      table.insert(new_tasks, task)
    end
  end
  return new_tasks
end

return finder
