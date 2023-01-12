local enum = require "telescope._extensions.tasks.enum"
local cache = require "telescope._extensions.tasks.generators.cache"
local output_buffer = require "telescope._extensions.tasks.output.buffer"

local running_tasks = {}
local buffers_to_delete = {}

local run_task

local executor = {}

---Returns the buffer number for the task identified
---by the provided name.
---
---@param name string: name of an task
---@return number?: the buffer number
function executor.get_task_output_buf(name)
  if running_tasks[name] == nil then
    return nil
  end
  return running_tasks[name].buf
end

function executor.is_running(name)
  return running_tasks[name] and running_tasks[name].job
end

---Returns the buffer number for the task identified
---by the provided name.
---
---@param name string: name of an task
---@return number?: the buffer number
function executor.get_job_id(name)
  if running_tasks[name] == nil then
    return nil
  end
  return running_tasks[name].job
end

---Returns the number of currently running tasks.
---
---@return number
function executor.get_running_tasks_count()
  local i = 0
  for _, _ in pairs(running_tasks) do
    i = i + 1
  end
  return i
end

---@param name string: The name of the task to run
---@param on_exit function: A function called when a started task exits.
---@return boolean: whether the tasks started successfully
function executor.run(name, on_exit)
  if executor.is_running(name) == true then
    vim.notify("Task '" .. name .. "' is already running!", vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return false
  end
  local task, err = cache.get_current_task_by_name(name)
  if err ~= nil then
    vim.notify(err, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return false
  end

  local ok, r = pcall(run_task, task, on_exit)
  if not ok and type(r) == "string" then
    vim.notify(r, vim.log.levels.ERROR, {
      title = enum.TITLE,
    })
    return false
  end
  return r
end

---Stop a running task.
---
---@param name string: Name of the task to be stopped
function executor.kill(name)
  local task, err = cache.get_current_task_by_name(name)
  if err ~= nil then
    vim.notify(err, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return false
  elseif task == nil then
    return false
  end
  if running_tasks[task.name] == nil then
    return false
  end
  local job = running_tasks[task.name].job
  pcall(vim.fn.jobstop, job)
  return true
end

---Delete the task buffer and kill it's job if is is running.
---@param name string: A running task's name
function executor.delete_task_buffer(name)
  buffers_to_delete[name] = nil

  local job = executor.get_job_id(name)
  local buf = executor.get_task_output_buf(name)
  if buf == nil then
    vim.notify(
      "Task '" .. name .. "' has no output buffer!",
      vim.log.levels.WARN,
      {
        title = enum.TITLE,
      }
    )
    return
  end
  local ok, err = pcall(function()
    if job then
      pcall(vim.fn.jobstop, job)
    end
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.notify(name .. ": output buffer deleted", vim.log.levels.INFO, {
      title = enum.TITLE,
    })
  end)
  if not ok and type(err) == "string" then
    vim.notify(err, vim.log.levels.ERROR, {
      title = enum.TITLE,
    })
    return
  end

  running_tasks[name] = nil
end

function executor.buffer_is_to_be_deleted(name)
  return buffers_to_delete[name]
end

function executor.set_buffer_as_to_be_deleted(name)
  buffers_to_delete[name] = true
end

---Returns the callback function called when
---the task's job exits.
local function on_task_exit(task, callback)
  return function(_, code)
    if running_tasks[task.name] ~= nil then
      running_tasks[task.name].job = nil
    end
    if callback then
      callback(code)
    end
    vim.notify(task.name .. ": exited with code: " .. code, vim.log.levels.INFO, {
      title = enum.TITLE,
    })
  end
end

---Try to name the buffer with the task's name, add index to
---the end of it, in case a buffer with the same
---name is already loaded
local function name_output_buf(buf, task)
  for i = 0, 100 do
    local name = task.name
    if i > 0 then
      name = name .. "_" .. i
    end
    local ok, _ = pcall(vim.api.nvim_buf_set_name, buf, name)
    if ok then
      break
    end
  end
end

run_task = function(task, on_exit)
  -- NOTE: Gather job options from the task
  local cmd = task.cmd
  local opts = {
    env = next(task.env or {}) and task.env or nil,
    cwd = task.cwd,
    clear_env = false,
    detach = false,
    on_exit = on_task_exit(task, on_exit),
  }

  --NOTE: if an output buffer for the same task already exists,
  --open terminal in that one instead of creating a new one
  local term_buf =
    output_buffer.create(executor.get_task_output_buf(task.name))
  if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
    return false
  end

  --NOTE: open a terminal in the created buffer and run
  --the task in it
  vim.api.nvim_buf_call(term_buf, function()
    vim.fn.termopen(cmd, opts)
  end)

  name_output_buf(term_buf, task)

  running_tasks[task.name] = {
    job = job_id,
    buf = term_buf,
  }
  return true
end

return executor
