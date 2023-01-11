local cached_tasks = {}
local current_tasks = {}

local cache = {}

---@return table: Currently available tasks
function cache.get_current_tasks()
  return current_tasks or {}
end

---@return table|nil: The task identified by the provided name
function cache.get_current_task_by_name(name)
  return cache.get_current_tasks()[name]
end

---Cache the provided tasks based on the current
---filetype and working directory.
---
---@param tasks table: A table of tasks to cache
---@return table: The cached tasks
function cache.set_for_current_context(tasks)
  local buf = vim.fn.bufnr()
  local cwd = vim.fn.getcwd()

  cached_tasks[buf] = {
    cwd = cwd,
    tasks = tasks,
  }
  current_tasks = tasks
  return tasks
end

---Get the cached tasks based on the current buffer
---and working directory.
---When the working directory has changed, the cache
---is cleared for the buffer and nil is returned.
---
---@return table|nil: The cached tasks
function cache.get_for_current_context()
  local buf = vim.fn.bufnr()
  local cwd = vim.fn.getcwd()

  local cached = cached_tasks[buf]
  if cached and cached.cwd == cwd then
    current_tasks = cached.tasks
    return cached.tasks
  end
  cached_tasks[buf] = nil
  return nil
end

---@return boolean: Whether there are no entries in the cache
function cache.is_empty()
  return next(cached_tasks) == nil
end

return cache
