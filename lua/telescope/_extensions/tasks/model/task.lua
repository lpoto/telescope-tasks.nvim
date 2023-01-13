---@class Task
---@field name string: This is taken from the key in vim.g.telescope_tasks table
---@field env table: A table of environment variables.
---@field cmd table|string: The command, may either be a string or a table. When a table, the first element should be executable.
---@field cwd string: The working directory of the task.
---@field __generator_opts table|nil

---@type Task
local Task = {}
Task.__index = Task

---Create an task from a table
---
---@param o table|string: Task's fields or just a command.
---@param generator_opts table|nil: The options of the generator that created this task.
---@return Task
function Task:new(o, generator_opts)
  ---@type Task
  local a = {
    __generator_opts = generator_opts,
  }
  setmetatable(a, Task)

  --NOTE: verify task's fields,
  --if any errors occur, stop with the creation and return
  --the error string.
  if type(o) == "string" then
    o = { o }
  elseif type(o) ~= "table" then
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
  end
  assert(type(o) == "table", "Task should be a table or a string!")

  local name = o.name or o[1]
  assert(type(name) == "string", "Task's 'name' should be a string!")
  a.name = name

  local cmd = o.cmd
  assert(
    type(cmd) == "table" or type(cmd) == "string",
    "Task '" .. a.name .. "' should have a string or a table `cmd` field!"
  )
  a.cmd = cmd

  local cwd = o.cwd
  assert(
    cwd == nil or type(cwd) == "string",
    "Task '" .. a.name .. "'s `cwd` field should be a string!"
  )
  a.cwd = cwd or vim.fn.getcwd()

  local env = o.env
  assert(
    env == nil or type(env) == "table",
    "Task '" .. a.name .. "'s env should be a table!"
  )
  a.env = o.env or {}

  return a
end

local quote_string
function Task:to_yaml_definition()
  local def = {}
  table.insert(def, "name: " .. quote_string(self.name))
  local cmd = self.cmd
  if type(cmd) == "string" then
    table.insert(def, "cmd: " .. quote_string(cmd))
  elseif type(cmd) == "table" then
    table.insert(def, "cmd: ")
    for _, v in ipairs(cmd) do
      if type(v) == "string" then
        table.insert(def, "  - " .. quote_string(v))
      else
        table.insert(def, "  - " .. quote_string(vim.inspect(v)))
      end
    end
  end
  if type(self.cwd) == "string" then
    table.insert(def, "cwd: " .. quote_string(self.cwd))
  else
    table.insert(def, "cwd: " .. quote_string(vim.inspect(self.cwd)))
  end
  table.insert(def, "env: ")
  for k, v in pairs(self.env) do
    table.insert(def, "  " .. k .. ": " .. quote_string(v))
  end

  if self.__generator_opts then
    table.insert(def, "")
    table.insert(def, "# generator:")
    if next(self.__generator_opts or {}) then
      if self.__generator_opts.name then
        table.insert(
          def,
          "#   name: " .. quote_string(self.__generator_opts.name)
        )
      end
      for k, v in pairs(self.__generator_opts) do
        if k ~= "name" and type(v) == "table" then
          local s = {}
          for _, v2 in ipairs(v) do
            table.insert(s, quote_string(v2))
          end
          local str = table.concat(s, ", ")
          table.insert(def, "#   " .. k .. ": " .. "[" .. str .. "]")
        end
      end
    end
  end
  return def
end

quote_string = function(v)
  if
    type(v) == "string"
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

return Task
