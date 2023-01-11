local enum = require "telescope._extensions.tasks.enum"
local run = require "telescope._extensions.tasks.executor.run_task"
local cache = require "telescope._extensions.tasks.generators.cache"

local executor = {}

---Returns true if the tasks identified
---by the provided name is running, false otherwise.
---
---@param name string: name of an task
---@return boolean
function executor.is_running(name)
  return run.get_job_id(name) ~= nil
end

---Returns the output buffer number of the task,
---or nil, if there is none.
---
---@param name string: name of an task
---@return number?: the output buffer number
function executor.get_task_output_buf(name)
  return run.get_buf_num(name)
end

---Deletes the output of the task and kills it
---it is running.
---
---@param name string: name of an task
function executor.delete_task_buffer(name)
  return run.delete_task_buffer(name)
end

---Run the task identified by the provided name
---
---@param name string: name of the task which the task is executed
---@param on_exit function: function called when the task exits.
---@return boolean: whether the task was started successfully
function executor.start(name, on_exit)
  --NOTE: fetch the task's data in the buffer from
  --which it has been started.
  ---@type Task|nil
  local task, err = cache.get_current_task_by_name(name)
  if err ~= nil then
    vim.notify(err, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return false
  elseif task == nil then
    return false
  end
  if executor.is_running(task.name) == true then
    vim.notify("Task '" .. name .. "' is already running!", vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return false
  end
  if run.get_running_tasks_count() >= enum.MAX_RUNNING_JOBS then
    vim.notify(
      "Can only run " .. MAX_RUNNING_JOBS .. " tasks at once!",
      vim.log.levels.WARN,
      {
        title = enum.TITLE,
      }
    )
    return false
  end
  return run.run(task, on_exit)
end

---Kill the task identified by the provided name
---
---@param name string: name of the task
---@return boolean: whether the task has been successfully killed
function executor.kill(name)
  ---@type Task|nil
  local task, err = cache.get_current_task_by_name(name)
  if err ~= nil then
    vim.notify(err, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return false
  elseif task == nil then
    return false
  end
  return run.stop(task)
end

return executor
