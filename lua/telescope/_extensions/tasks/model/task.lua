local util = require "telescope._extensions.tasks.util"
local storage = require "telescope._extensions.tasks.storage"

---@class Task
---@field name string: This is taken from the key in vim.g.telescope_tasks table
---@field env table: A table of environment variables.
---@field cmd table|string: The command, may either be a string or a table. When a table, the first element should be executable.
---@field filename string?: The task's reference file, which may be opened from the picker.
---@field cwd string: The working directory of the task.
---@field errorformat string|nil
---@field __generator_opts table|nil
---@field __meta string[]
---@field create_job function
---@field __update_from_storage function
---@field __modify_command_from_input function

---@type Task
local Task = {
  __orig_cmd = nil,
}
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

  local filename = o.filename
  assert(
    filename == nil or type(filename) == "string",
    "Task '" .. a.name .. "'s `filename` field should be a string!"
  )
  a.filename = filename

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

  if type(o.__meta) == "table" then
    for k, v in pairs(o.__meta) do
      assert(
        type(v) == "string" and type(k) == "number",
        "__meta should be a table of strings!"
      )
    end
  else
    assert(
      o.__meta == nil or type(o.__meta) == "table",
      "__meta field should be a table"
    )
  end
  a.__meta = o.__meta
  a.cmd = format_cmd(a.cmd)
  a.__orig_cmd = format_cmd(a.cmd)

  return a:__update_from_storage()
end

---Create a job from the task's fields.
---Returns a function that startes the job in the provided buffer
---and returns the started job's id.
---
---@return function?
function Task:create_job(callback, lock, save_modified_command)
  self:__update_from_storage()

  local opts = {
    env = next(self.env or {}) and self.env or nil,
    cwd = self.cwd,
    clear_env = false,
    detach = false,
    on_exit = callback,
  }

  local cmd
  if not lock then
    cmd = self:__modify_command_from_input(save_modified_command)
  else
    cmd = format_cmd(self.cmd)
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

function Task:get_definition()
  local def = {}
  table.insert(def, { key = "name", value = self.name })
  local cmd = self.cmd
  if type(cmd) == "string" then
    table.insert(def, { key = "cmd", value = cmd })
  elseif type(cmd) == "table" then
    table.insert(
      def,
      { key = "cmd", value = "[" .. table.concat(cmd, ", ") .. "]" }
    )
  else
    table.insert(def, { key = "cmd", value = table.concat(cmd) })
  end
  if type(self.cwd) == "string" then
    table.insert(def, { key = "cwd", value = self.cwd })
  else
    table.insert(def, { key = "cwd", vim.inspect(self.cwd) })
  end
  if type(self.env) == "table" then
    table.insert(
      def,
      { key = "env", value = "[" .. table.concat(self.env, ", ") .. "]" }
    )
  end

  if self.__generator_opts then
    table.insert(def, {})
    if next(self.__generator_opts or {}) and self.__generator_opts.name then
      table.insert(
        def,
        { key = "#  generator", value = self.__generator_opts.name }
      )
      for k, v in pairs(self.__generator_opts) do
        if k ~= "name" and type(v) == "table" then
          table.insert(
            def,
            { key = "#   " .. k, value = "[" .. table.concat(v, ", ") .. "]" }
          )
        elseif k == "experimental" and v then
          table.insert(def, { key = "#   " .. k, value = "true" })
        end
      end
    end
  end
  return def
end

function Task:__update_from_storage()
  local task_stored_data = storage.get(self.__meta)
  if
    type(task_stored_data) == "table"
    and (
      type(task_stored_data.cmd) == "string"
      or type(task_stored_data.cmd) == "table"
    )
  then
    self.cmd = format_cmd(task_stored_data.cmd)
  end
  return self
end

function Task:__modify_command_from_input(save_modified_command)
  local orig_cmd = format_cmd(self.__orig_cmd)
  local cmd = format_cmd(self.cmd)

  local cmd2 = vim.fn.input {
    prompt = "$ ",
    default = cmd .. " ",
    cancelreturn = false,
  }
  if type(cmd2) ~= "string" then
    return nil
  end
  if cmd2 == "" then
    cmd2 = orig_cmd
  else
    cmd2 = format_cmd(cmd2)
  end

  local set_cmd = false
  if save_modified_command then
    if cmd2 == orig_cmd then
      storage.delete(self.__meta)
      set_cmd = true
    elseif cmd2 ~= cmd then
      storage.save(self.__meta, { cmd = cmd2 })
      set_cmd = true
    end
  end
  cmd = format_cmd(cmd2)
  if set_cmd then
    self.cmd = cmd
  end
  return cmd
end

---@param cmd string|table
---@return string
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
  local s = table.concat(cmd2, " ")
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

return Task
