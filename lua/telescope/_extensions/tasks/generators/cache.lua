local cached_tasks = {}

local cache = {}

---Cache the provided tasks based on the current
---filetype and working directory.
---
---@param tasks table: A table of tasks to cache
---@return table: The cached tasks
function cache.set_for_current_context(tasks)
  local buf = vim.fn.bufnr()
  local cwd = vim.fn.getcwd()
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")

  cached_tasks[filetype] = {
    cwd = cwd,
    tasks = tasks,
  }
  return tasks
end

---Get the cached tasks based on the current filetype
---and working directory.
---When the working directory has changed, the cache
---is cleared for the filetype and nil is returned.
---
---@return table|nil: The cached tasks
function cache.get_for_current_context()
  local buf = vim.fn.bufnr()
  local cwd = vim.fn.getcwd()
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")

  local cached = cached_tasks[filetype]
  if cached and cached.cwd == cwd then
    return cached.tasks
  end
  cached_tasks[filetype] = nil
  return nil
end

---@return boolean: Whether there are no entries in the cache
function cache.is_empty()
  return not next(cached_tasks) == nil
end

return cache
