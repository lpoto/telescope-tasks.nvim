local util = require "telescope._extensions.tasks.util"
local output_buffer = require "telescope._extensions.tasks.output.buffer"

local idx = 0
local running_tasks = {}
local buffers_to_delete = {}
local timestamps = {}

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
  local buf = running_tasks[name].buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end
  return buf
end

function executor.is_running(name)
  return executor.get_job_id(name) ~= nil
end

---Returns the timestamp of the last run of the task
---identified by the provided name.
---
---@param name string: name of an task
---@return number?: the timestamp
function executor.get_task_latest_timestamp(name)
  return timestamps[name]
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

---Get all currently running tasks
---
---@return table
function executor.get_running_tasks()
  local tasks = {}
  for _, o in pairs(running_tasks or {}) do
    tasks[o.task.name] = o.task
  end
  return tasks
end

---Get the name of the first found task that currently
---has an existing output buffer.
---@return string|nil
function executor.get_name_of_first_task_with_output()
  for _, o in pairs(running_tasks or {}) do
    local buf = executor.get_task_output_buf(o.task.name)
    if buf and vim.api.nvim_buf_is_valid(buf) then
      return o.task.name
    end
  end
  return nil
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

---@param task Task: The task to run
---@param on_exit function: A function called when a started task exits.
---@param on_start function: A function called when a task is started
---@param lock boolean: Whether to allow modyfing the executed command or not
function executor.run(task, on_exit, on_start, lock)
  if executor.is_running(task.name) == true then
    util.warn("Task '" .. task.name .. "' is already running!")
    return false
  end

  local on_exit2 = function(...)
    timestamps[task.name] = os.time()
    if type(on_exit) == "function" then
      on_exit(...)
    end
  end

  local safely_run = function()
    local ok, r = pcall(run_task, task, on_exit2, lock)
    if not ok and type(r) == "string" then
      util.error(r)
      return false
    end
    if r then
      timestamps[task.name] = os.time()
      on_start()
    end
    return r
  end

  return safely_run()
end

---Stop a running task.
---
---@param task Task: The task to kill
function executor.kill(task)
  if running_tasks[task.name] == nil then
    return false
  end
  local job = running_tasks[task.name].job
  pcall(vim.fn.jobstop, job)
  return true
end

---Delete the task buffer and kill it's job if is is running.
---@param task Task: The task to delete the buffer for
function executor.delete_task_buffer(task)
  buffers_to_delete[task.name] = nil

  local job = executor.get_job_id(task.name)
  local buf = executor.get_task_output_buf(task.name)
  if buf == nil then
    util.warn("Task '" .. task.name .. "' has no output buffer!")
    return
  end
  local ok, err = pcall(function()
    if job then
      pcall(vim.fn.jobstop, job)
    end
    vim.api.nvim_buf_delete(buf, { force = true })
    util.info(task.name .. ": output buffer deleted")
  end)
  if not ok and type(err) == "string" then
    vim.error(err)
    return
  end

  running_tasks[task.name] = nil
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
    util.info(task.name .. ": exited with code:", code)
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

---@param task Task
---@param on_exit function?
run_task = function(task, on_exit, lock)
  --open terminal in that one instead of creating a new one
  local term_buf =
      output_buffer.create(executor.get_task_output_buf(task.name))
  if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
    return false
  end

  -- NOTE: Gather job options from the task
  local job = task:create_job(on_task_exit(task, on_exit), lock)
  if not job then
    return
  end

  local job_id = job(term_buf)

  if not job_id then
    pcall(vim.api.nvim_buf_delete, term_buf, { force = true })
  end

  name_output_buf(term_buf, task)

  running_tasks[task.name] = {
    job = job_id,
    buf = term_buf,
    task = task,
    idx = idx,
    name = task.name,
  }
  idx = idx + 1
  return true
end

function executor.get_last_task_output_buf()
  local v = vim.tbl_values(running_tasks)
  table.sort(v, function(a, b)
    return a.idx > b.idx
  end)
  if next(v) == nil then
    return nil
  end
  for _, t in ipairs(v) do
    if t.buf and vim.api.nvim_buf_is_valid(t.buf) then
      return t.buf, t.name
    end
  end
  return nil
end

function executor.mark_task_as_latest(name)
  if running_tasks[name] then
    running_tasks[name].idx = idx
    idx = idx + 1
  end
end

function executor.to_qf(task)
  if not task.errorformat then
    util.warn("Task '" .. task.name .. "' has no errorformat!")
    return
  end
  local buf = executor.get_task_output_buf(task.name)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    util.warn("Task '" .. task.name .. "' has no output buffer!")
    return
  end
  local ok, e = pcall(function()
    vim.api.nvim_buf_set_option(buf, "errorformat", task.errorformat)
    vim.api.nvim_exec("noautocmd cgetbuffer " .. buf, false)
  end)
  if not ok and type(e) == "string" then
    util.error(e)
    return
  end
  util.info(task.name .. ": " .. "Output send to quickfix")
end

function executor.get_task_from_buffer(buf)
  for _, t in pairs(running_tasks) do
    if t.buf == buf then
      return t.task
    end
  end
  return nil
end

return executor
