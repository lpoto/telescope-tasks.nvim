---@class Task
---@field name string: This is taken from the key in vim.g.telescope_tasks table
---@field env table|nil: A table of environment variables.
---@field cmd table|string: The command, may either be a string or a table. When a table, the first element should be executable.
---@field cwd string|nil: The working directory of the task.
---@field filetypes table|nil: Filetypes in which the task is available.
---@field patterns table|nil: Task is available ony in files with names that match a pattern in this table of lua patterns.
---@field ignore_patterns table|nil: Task is not available in files with names that match a pattern in this table of lua patterns.

---@type Task
local Task = {}
Task.__index = Task

---Create an task from a table
---
---@param o table|string: Task's fields or just a command.
---@param name string: Task's name.
---@return Task
---@return string?: An error that occured when creating an Task.
function Task.__create(name, o)
  ---@type Task
  local a = {}
  setmetatable(a, Task)

  --NOTE: verify task's fields,
  --if any errors occur, stop with the creation and return
  --the error string.

  if name == nil or type(name) ~= "string" then
    return a, "Task's 'name' should be a string!"
  end
  a.name = name

  if type(o) == "string" then
    o = { o }
  elseif type(o) == "table" then
    local ok = true
    for k, v in pairs(o) do
      if type(k) ~= "number" or type(v) ~= "string" then
        ok = false
        break
      end
    end
    if ok then
      o = { o }
    end
  else
    return a, "Task '" .. name .. "' should be a table!"
  end

  local cmd = o.cmd or o[1]
  if cmd == nil then
    return a, "Task '" .. name .. "' should have a `cmd` field!"
  end
  if type(cmd) == "string" then
    a.cmd = cmd
  elseif type(cmd) == "table" then
    for k, v in ipairs(cmd) do
      if type(v) ~= "string" or type(k) ~= "number" then
        return a, "Task '" .. name .. "'s command is invalid!"
      end
    end
    a.cmd = cmd
  else
    return a, "Task '" .. name .. "'s command should be a string or a table!"
  end

  if o.filetypes ~= nil and type(o.filetypes) ~= "table" then
    return a, "Task '" .. name .. "'s filetypes should be a table!"
  end
  a.filetypes = o.filetypes
  if o.patterns ~= nil and type(o.patterns) ~= "table" then
    return a, "Task '" .. name .. "'s patterns should be a table!"
  end
  a.patterns = o.patterns
  if o.ignore_patterns ~= nil and type(o.ignore_patterns) ~= "table" then
    return a, "Task '" .. name .. "'s ignore_patterns should be a table!"
  end
  a.ignore_patterns = o.ignore_patterns
  if o.cwd ~= nil and type(o.cwd) ~= "string" then
    return a, "Task '" .. name .. "'s cwd should be a string!"
  end
  a.cwd = o.cwd
  if o.env ~= nil and type(o.env) ~= "table" then
    return a, "Task '" .. name .. "'s env should be a table!"
  end
  a.env = o.env
  return a
end

---Checks whether the task is available. It is available when
---the current filename matches it's patterns and the current filetype
---matches it's filetypes.
---
---@param a Task
---@return boolean
function Task.__is_available(a)
  local filetypes = a.filetypes
  local current_filetype = vim.o["filetype"]
  local continue = filetypes == nil or next(filetypes) == nil
  if filetypes ~= nil then
    for _, ft in ipairs(filetypes) do
      if ft == current_filetype then
        continue = true
        break
      end
    end
  end
  if continue == false then
    return false
  end
  local filename = vim.fn.expand "%:p"

  local ignore_patterns = a.ignore_patterns
  if ignore_patterns ~= nil then
    for _, p in ipairs(ignore_patterns) do
      if string.find(filename, p) ~= nil then
        return false
      end
    end
  end

  local patterns = a.patterns
  if patterns == nil or next(patterns) == nil then
    return true
  end
  for _, p in ipairs(patterns) do
    if string.find(filename, p) ~= nil then
      return true
    end
  end
  return false
end

function Task.__available_tasks(temp_buf)
  local all_tasks = vim.g["telescope_tasks"] or {}

  ---@type table
  local tasks_table = {}
  ---@type string?
  local e = nil
  local check = function()
    for name, task_f in pairs(all_tasks) do
      local task, err = Task.__create(name, task_f())
      if err ~= nil then
        e = err
        return
      end
      if Task.__is_available(task) then
        table.insert(tasks_table, task)
      end
    end
  end
  if temp_buf == nil or vim.fn.bufexists(temp_buf) ~= 1 then
    check()
  else
    vim.api.nvim_buf_call(temp_buf, check)
  end
  return tasks_table, e
end

function Task.__get(name, temp_buf)
  local all_tasks = vim.g["telescope_tasks"] or {}
  local task_f = all_tasks[name]

  if task_f == nil then
    return nil, "Task '" .. name .. "' does not exist!"
  end
  local a, e
  if temp_buf == nil or vim.fn.bufexists(temp_buf) ~= 1 then
    a, e = Task.__create(name, task_f())
  else
    vim.api.nvim_buf_call(temp_buf, function()
      a, e = Task.__create(name, task_f())
    end)
  end
  return a, e
end

return Task
