local util = require "telescope._extensions.tasks.util"
local setup = require "telescope._extensions.tasks.setup"

---@class Task
---@field name string: This is taken from the key in vim.g.telescope_tasks table
---@field env table: A table of environment variables.
---@field cmd table|string: The command, may either be a string or a table. When a table, the first element should be executable.
---@field cwd string: The working directory of the task.
---@field lock boolean|nil: When true, don't ask for input when creating a job.
---@field errorformat string|nil
---@field __generator_opts table|nil
---@field __meta table
---@field create_job function

---@type Task
local Task = {}
Task.__index = Task

local format_cmd

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

  local errorformat = o.errorformat
  assert(
    errorformat == nil or type(errorformat) == "string",
    "Task '" .. a.name .. "'s `errorformat` field should be a string!"
  )
  a.errorformat = errorformat

  local cmd = o.cmd
  assert(
    type(cmd) == "table" or type(cmd) == "string",
    "Task '" .. a.name .. "' should have a string or a table `cmd` field!"
  )
  if type(cmd) == "table" then
    local t = nil
    for k, v in pairs(cmd) do
      if t ~= nil then
        assert(
          type(k) == t,
          "cmd table should have either all number or all string keys."
        )
      end
      assert(
        (type(v) == "table" and type(k) == "string") or type(v) == "string",
        "Commands should have string or table values!"
      )
      t = type(k)
    end
  end
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

  local lock = o.lock
  assert(
    lock == nil or type(lock) == "boolean",
    "Task '" .. a.name .. "'s lock should be a boolean!"
  )
  a.lock = lock

  if type(o.__meta) == "table" then
    a.__meta = o.__meta
    if type(a.__meta.name) == "string" then
      local data_dir = setup.opts.data_dir
      if type(data_dir) == "string" then
        local data = util.fetch_data(data_dir, a.__meta.name)
        if type(data) == "string" then
          a.cmd = data
        end
      end
    end
  else
    assert(
      o.__meta == nil or type(o.__meta) == "table",
      "__meta field should be a table"
    )
  end

  a.cmd = format_cmd(a.cmd)

  return a
end

local copy_cmd

---Create a job from the task's fields.
---Returns a function that startes the job in the provided buffer
---and returns the started job's id.
---
---@return function?
function Task:create_job(callback)
  local cmd = self.cmd
  cmd = copy_cmd(cmd)

  local opts = {
    env = next(self.env or {}) and self.env or nil,
    cwd = self.cwd,
    clear_env = false,
    detach = false,
    on_exit = callback,
  }

  if not self.lock then
    local cmd_string = cmd
    if type(cmd_string) == "table" then
      cmd_string = table.concat(cmd_string, " ")
    end
    cmd_string = util.trim_string(cmd_string)

    local cmd_string2 = vim.fn.input("$ ", cmd_string .. " ")
    if not cmd_string2 or cmd_string2:len() == 0 then
      return nil
    end
    cmd_string2 = util.trim_string(cmd_string2)

    local set_cmd = false
    if type(self.__meta) == "table" and type(self.__meta.name) == "string" then
      if cmd_string2 ~= cmd_string then
        local data_dir = setup.opts.data_dir
        if type(data_dir) == "string" then
          util.save_data(data_dir, self.__meta.name, cmd_string2)
          set_cmd = true
        end
      end
    end
    cmd = format_cmd(cmd_string2)
    if set_cmd then
      self.cmd = cmd
    end
  end

  return function(buf)
    local job_id = nil
    vim.api.nvim_buf_call(buf, function()
      local ok, id = pcall(vim.fn.termopen, cmd, opts)
      if not ok and type(id) == "string" then
        util.error(id)
      else
        job_id = id
      end
    end)
    return job_id
  end
end

local quote_string
local quote_table
function Task:to_yaml_definition()
  local def = {}
  table.insert(def, "name: " .. quote_string(self.name))
  local cmd = self.cmd
  if type(cmd) == "string" then
    table.insert(def, "cmd: " .. quote_string(cmd))
  elseif type(cmd) == "table" then
    local k, _ = next(cmd)
    if type(k) == "string" then
      table.insert(def, "cmd:")
      for key, value in pairs(cmd) do
        if type(value) == "string" then
          table.insert(def, "  " .. key .. ": " .. quote_string(value))
        elseif type(value) == "table" then
          table.insert(
            def,
            "  "
              .. key
              .. ": ["
              .. table.concat(quote_table(value), ", ")
              .. "]"
          )
        end
      end
    else
      table.insert(
        def,
        "cmd: " .. "[" .. table.concat(quote_table(cmd), ", ") .. "]"
      )
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
        elseif k == "experimental" and v then
          table.insert(def, "#   " .. k .. ": " .. "true")
        end
      end
    end
  end
  return def
end

quote_table = function(v)
  local t = {}
  for k, s in pairs(v) do
    if type(s) == "string" then
      t[k] = quote_string(s)
    else
      t[k] = s
    end
  end
  return t
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

copy_cmd = function(cmd)
  local _cmd = nil
  if type(cmd) == "string" then
    _cmd = cmd
  elseif type(cmd) == "table" then
    _cmd = {}
    for _, v in ipairs(cmd) do
      table.insert(_cmd, v)
    end
  end
  return _cmd
end

format_cmd = function(cmd)
  local cmd2 = {}
  if type(cmd) == "string" then
    cmd = vim.split(cmd, " ")
  end
  for _, v in ipairs(cmd) do
    if type(v) == "string" and v:len() > 0 then
      table.insert(cmd2, v)
    end
  end
  if #cmd2 == 0 then
    return ""
  end
  cmd = cmd2
  if vim.fn.executable(cmd[1]) ~= 1 then
    cmd = table.concat(cmd, " ")
  end
  return cmd
end

return Task
