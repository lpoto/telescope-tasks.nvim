---@class Task
---@field name string: This is taken from the key in vim.g.telescope_tasks table
---@field env table: A table of environment variables.
---@field cmd table|string: The command, may either be a string or a table. When a table, the first element should be executable.
---@field cwd string: The working directory of the task.
---@field __generator_name string|nil

---@type Task
local Task = {}
Task.__index = Task

---Create an task from a table
---
---@param o table|string: Task's fields or just a command.
---@param generator_name stirng?: The name of the generator that created this task.
---@return Task
---@return string?: An error that occured when creating an Task.
function Task.__create(o, generator_name)
  ---@type Task
  local a = {
    __generator_name = generator_name,
  }
  setmetatable(a, Task)

  --NOTE: verify task's fields,
  --if any errors occur, stop with the creation and return
  --the error string.

  local name = o.name or o[1]
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
    return a, "Task '" .. a.name .. "' should be a table!"
  end

  if o.cmd == nil then
    return a, "Task '" .. a.name .. "' should have a `cmd` field!"
  end
  if type(o.cmd) == "string" then
    a.cmd = o.cmd
  elseif type(o.cmd) == "table" then
    for k, v in ipairs(o.cmd) do
      if type(v) ~= "string" or type(k) ~= "number" then
        return a, "Task '" .. a.name .. "'s command is invalid!"
      end
    end
    a.cmd = o.cmd
  else
    return a, "Task '" .. a.name .. "'s command should be a string or a table!"
  end
  a.cwd = o.cwd or vim.fn.getcwd()
  if o.env ~= nil and type(o.env) ~= "table" then
    return a, "Task '" .. a.name .. "'s env should be a table!"
  end
  a.env = o.env or {}
  return a
end

local quote_string
function Task:to_yaml_definition()
  local def = {}
  table.insert(def, "name: " .. quote_string(self.name))
  local cmd = self.cmd
  if type(cmd) == "string" then
    table.insert(def, "cmd: " .. cmd)
  elseif type(cmd) == "table" then
    table.insert(def, "cmd: ")
    for _, v in ipairs(cmd) do
      table.insert(def, "  - " .. v)
    end
  end
  table.insert(def, "cwd: " .. self.cwd)
  table.insert(def, "env: ")
  for k, v in pairs(self.env) do
    table.insert(def, "  " .. k .. ": " .. quote_string(v))
  end

  if self.__generator_name ~= nil then
    table.insert(def, "")
    table.insert(def, "# generator: " .. quote_string(self.__generator_name))
  end
  return def
end

quote_string = function(v)
  if type(v) == "string"
      and (string.find(v, "'") or string.find(v, "`") or string.find(v, '"'))
  then
    if string.find(v, "'") == nil then
      v = "'" .. v .. "'"
    elseif string.find(v, '"') == nil then
      v = '"' .. v .. '"'
    elseif string.find(v, "`") == nil then
      v = "`" .. v .. "`"
    end
  end
  return v
end

get_task_definition = function(task) end

return Task
