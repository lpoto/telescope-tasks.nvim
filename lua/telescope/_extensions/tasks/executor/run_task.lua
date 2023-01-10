local enum = require "telescope._extensions.tasks.enum"
local create_buffer =
  require "telescope._extensions.tasks.executor.create_buffer"

---A table with tasks' names as keys
---and their job ids as values
---
---@type table
local running_tasks = {}

local run = {}

---Returns the buffer number for the task identified
---by the provided name.
---
---@param name string: name of an task
---@return number?: the buffer number
function run.get_buf_num(name)
  if running_tasks[name] == nil then
    return nil
  end
  return running_tasks[name].buf
end

---Returns the buffer number for the task identified
---by the provided name.
---
---@param name string: name of an task
---@return number?: the buffer number
function run.get_job_id(name)
  if running_tasks[name] == nil then
    return nil
  end
  return running_tasks[name].job
end

---Returns the number of currently running tasks.
---
---@return number
function run.get_running_tasks_count()
  local i = 0
  for _, _ in pairs(running_tasks) do
    i = i + 1
  end
  return i
end

---@param task Task: task to be run
---@param on_exit function: A function called when a started task exits.
---@return boolean: whether the tasks started successfully
function run.run(task, on_exit)
  local env = task.env ~= nil and next(task.env) ~= nil and task.env or nil
  local cwd = task.cwd

  local cmd = task.cmd

  --NOTE: if an output buffer for the same task already exists,
  --open terminal in that one instead of creating a new one
  local term_buf = create_buffer.create(run.get_buf_num(task.name))
  if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
    return false
  end

  --NOTE: open a terminal in the created buffer
  --set the terminal's properties to match the task
  local ok, job_id
  local ok1, err = pcall(vim.api.nvim_buf_call, term_buf, function()
    ok, job_id = pcall(vim.fn.termopen, cmd, {
      cwd = cwd,
      env = env,
      clear_env = true,
      detach = false,
      on_exit = function(_, code)
        if running_tasks[task.name] ~= nil then
          running_tasks[task.name].job = nil
        end
        on_exit(code)
      end,
    })
  end)
  if ok1 == false then
    vim.notify(err, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return false
  end
  --NOTE: if job_id is string, it means
  --an error occured when starting the task
  if ok == false then
    vim.notify(job_id, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return false
  end
  --NOTE: try to name the buffer, add index to
  --the end of it, in case a buffer with the same
  --name is already loaded
  for i = 0, 20 do
    local name = task.name
    if i > 0 then
      name = name .. "_" .. i
    end
    local ok, _ = pcall(vim.api.nvim_buf_set_name, term_buf, name)
    if ok == true then
      break
    end
  end
  --NOTE: set some options for the output buffer,
  --make sure it is not modifiable and that it is hidden
  --when closing it.
  --Set it's filetype to 'task_output' so it differs from
  --other terminal windows.
  vim.api.nvim_buf_set_option(term_buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(term_buf, "modifiable", false)
  vim.api.nvim_buf_set_option(term_buf, "modified", false)
  vim.api.nvim_buf_set_option(
    term_buf,
    "filetype",
    enum.OUTPUT_BUFFER_FILETYPE
  )

  running_tasks[task.name] = {
    job = job_id,
    buf = term_buf,
  }
  return true
end

---Stop a running task.
---
---@param task Task: Task to be stopped
function run.stop(task)
  if running_tasks[task.name] == nil then
    return false
  end
  local job = running_tasks[task.name].job
  pcall(vim.fn.jobstop, job)
  return true
end

function run.delete_task_buffer(name)
  if running_tasks[name] == nil then
    return
  end
  local job = running_tasks[name].job
  pcall(vim.fn.jobstop, job)
  pcall(vim.fn.nvim_buf_delete, running_tasks[name].buf, { force = true })
  running_tasks[name] = nil
end

return run
