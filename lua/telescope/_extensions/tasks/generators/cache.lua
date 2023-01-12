local cached_tasks = {}
local current_tasks = {}

local cache = {}

---@return table: Currently available tasks
function cache.get_current_tasks()
  return current_tasks or {}
end

---@return table|nil: The task identified by the provided name
function cache.get_task_by_name(name)
  local task = cache.get_current_tasks()[name]
  if task then
    return task
  end
  for _, tbl in pairs(cached_tasks) do
    task = (tbl.tasks or {})[name]
    if task then
      return task
    end
  end
  return nil
end

---Cache the provided tasks based on the current
---filetype and working directory.
---
---@param tasks table: A table of tasks to cache
---@return table: The cached tasks
function cache.set_for_current_context(tasks)
  local buf = vim.fn.bufnr()
  local cwd = vim.fn.getcwd()
  local name = vim.api.nvim_buf_get_name(buf)

  if tasks ~= nil then
    cached_tasks[buf] = {
      cwd = cwd,
      tasks = tasks,
      name = name,
    }
  end
  current_tasks = tasks or {}
  return tasks or {}
end

---Same as cache.set_for_current_context, but the
---cached tasks are updated instead of replaced
---@param tasks table
---@return table
function cache.add_to_current_context(tasks)
  local buf = vim.fn.bufnr()
  local cwd = vim.fn.getcwd()
  local name = vim.api.nvim_buf_get_name(buf)

  local existing_tasks = not cached_tasks[buf] and {}
    or cached_tasks[buf].tasks
    or {}

  if tasks ~= nil then
    existing_tasks = vim.tbl_extend("force", existing_tasks, tasks)
    cached_tasks[buf] = {
      cwd = cwd,
      tasks = existing_tasks,
      name = name,
    }
  end
  current_tasks = existing_tasks
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
  local name = vim.api.nvim_buf_get_name(buf)

  local cached = cached_tasks[buf]
  if cached and cached.cwd == cwd and name == cached.name then
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
