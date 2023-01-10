local tasks = {}

local current_tasks = {}

---@return table: A table of Task objects
function current_tasks.get_all()
  return tasks
end

---@param name string: A task's name
---@return Task?
function current_tasks.get_by_name(name)
  return tasks[name]
end

---Add a table of tasks to the current tasks
---
---@param to_add table: A table of Task objects
function current_tasks.add(to_add)
  for _, task in ipairs(to_add) do
    current_tasks[task.name] = task
  end
end

---Clear the current tasks
function current_tasks.reset()
  tasks = {}
end

return current_tasks
