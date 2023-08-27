local enum = require("telescope-tasks.enum")
local storage = require("telescope-tasks.storage")
local util = require("telescope-tasks.util")

---@class Task
---@field name string: This is taken from the key in vim.g.telescope_tasks table
---@field env table: A table of environment variables.
---@field cmd table|string: The command, may either be a string or a table. When a table, the first element should be executable.
---@field filename string?: The task's reference file, which may be opened from the picker.
---@field cwd string?: The working directory of the task.
---@field errorformat string|nil
---@field priority number
---@field keywords string[]
---@field __default_generator boolean
---@field __experimental boolean
---@field create_job function
---@field modify_command_from_input function
---@field modify_cwd_from_input function
---@field modify_env_from_input function
---@field delete_modifications function
---@field __update_from_storage function

---@type Task
local Task = {
  __orig_cmd = nil,
  __orig_env = nil,
  __orig_cwd = nil,
}
Task.__index = Task

local format_cmd

---Create an task from a table
---
---@param o table|string: Task's fields or just a command.
---@return Task
function Task:new(o)
  ---@type Task
  local a = setmetatable({}, Task)

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
    if ok then o = { o } end
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

  assert(
    o.priority == nil or type(o.priority) == "number",
    "Task '" .. a.name .. "'s `priority` field should be number!"
  )
  a.priority = o.priority or enum.PRIORITY.LOW

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

  if type(o.__experimental) == "boolean" then
    a.__experimental = o.__experimental
  end
  if type(o.__default_generator) == "boolean" then
    a.__default_generator = o.__default_generator
  end

  local cwd = o.cwd
  assert(
    cwd == nil or type(cwd) == "string",
    "Task '" .. a.name .. "'s `cwd` field should be a string!"
  )
  a.cwd = cwd or vim.fn.getcwd()
  a.__orig_cwd = a.cwd

  local env = o.env
  assert(
    env == nil or type(env) == "table",
    "Task '" .. a.name .. "'s env should be a table!"
  )
  a.env = o.env or {}
  a.__orig_env = vim.deepcopy(a.env)

  if
    type(o.keywords) == "table" and not next(o.keywords)
    or o.keywords == nil
  then
    local keywords = { "__derived" }
    if type(a.filename) == "string" then
      table.insert(keywords, "__file")
      table.insert(keywords, a.filename)
    end
    if type(a.name) == "string" then
      table.insert(keywords, "__name")
      table.insert(keywords, a.name)
    end
    if #keywords > 1 then a.keywords = keywords end
  elseif type(o.keywords) == "table" then
    for k, v in pairs(o.keywords) do
      assert(
        type(v) == "string" and type(k) == "number",
        "keywords should be a table of strings!"
      )
    end
    a.keywords = o.keywords
  else
    assert(false, "keywords field should be a table of strings!")
  end
  a.cmd = format_cmd(a.cmd)
  a.__orig_cmd = format_cmd(a.cmd)

  return a:__update_from_storage()
end

---Create a job from the task's fields.
---Returns a function that startes the job in the provided buffer
---and returns the started job's id.
---
---@return function?
function Task:create_job(callback)
  self:__update_from_storage()

  local opts = {
    env = next(self.env or {}) and self.env or nil,
    clear_env = false,
    detach = false,
    on_exit = callback,
  }
  if type(self.cwd) == "string" and self.cwd:len() > 0 then
    opts.cwd = self.cwd
  end
  local cmd = format_cmd(self.cmd)

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
    table.insert(def, { key = "cwd", value = "" })
  end
  if type(self.env) == "table" then
    table.insert(def, { key = "env", value = "" })
    if next(self.env) then
      for k, v in pairs(self.env) do
        table.insert(def, { key = "  " .. k, value = v })
      end
    end
  end

  table.insert(def, { key = "" })
  table.insert(def, { key = "" })
  if self.__default_generator then
    table.insert(def, { key = "#  Default generator" })
  else
    table.insert(def, { key = "#  Custom generator" })
  end
  if self.__experimental then
    table.insert(def, { key = "#  Experimental" })
  end
  if self:modified() then table.insert(def, { key = "#  Modified" }) end
  return def
end

function Task:__update_from_storage()
  local task_stored_data = storage.get(self.keywords)
  if type(task_stored_data) ~= "table" then return self end
  if
    type(task_stored_data.cmd) == "string"
    or type(task_stored_data.cmd) == "table"
  then
    self.cmd = format_cmd(task_stored_data.cmd)
  end
  if type(task_stored_data.env) == "table" then
    for k, v in pairs(task_stored_data.env) do
      if v == "" then
        self.env[k] = nil
      else
        self.env[k] = v
      end
    end
  end
  if type(task_stored_data.cwd) == "string" then
    self.cwd = task_stored_data.cwd
  end
  return self
end

---@return boolean
function Task:modify_command_from_input()
  local orig_cmd = format_cmd(self.__orig_cmd)
  local cmd = format_cmd(self.cmd)

  local cmd2 = vim.fn.input({
    prompt = "$ ",
    default = cmd .. " ",
    cancelreturn = false,
  })
  if type(cmd2) ~= "string" then return false end
  if cmd2 == "" then
    cmd2 = orig_cmd
  else
    cmd2 = format_cmd(cmd2)
  end

  local set_cmd = false
  if cmd2 == orig_cmd then
    storage.save(self.keywords, { cmd = enum.NIL })
    set_cmd = true
  elseif cmd2 ~= cmd then
    storage.save(self.keywords, { cmd = cmd2 })
    set_cmd = true
  end
  if set_cmd then
    self.cmd = format_cmd(cmd2)
    return true
  end
  return false
end

---@return boolean
function Task:modify_env_from_input()
  local key = vim.fn.input({
    prompt = "Environment variable name: ",
    default = "",
    cancelreturn = false,
  })
  if type(key) ~= "string" or key:len() == 0 then return false end
  local value = vim.fn.input({
    prompt = "Environment variable value: ",
    default = "",
    cancelreturn = false,
  })
  if type(value) ~= "string" then return false end
  if value == "" then
    if self.__orig_env[key] then
      local r = vim.fn.confirm(
        "Do you want to use default value for " .. key .. "?",
        "&Yes\n&No",
        2
      )
      if r == 1 then
        value = self.__orig_env[key]
        self.env[key] = value
      else
        self.env[key] = nil
      end
    else
      value = enum.NIL
      self.env[key] = nil
    end
  else
    self.env[key] = value
  end
  storage.save(self.keywords, { env = { [key] = value } })
  return true
end

function Task:modify_cwd_from_input()
  local cwd = vim.fn.input({
    prompt = "Working directory: ",
    default = self.cwd,
    cancelreturn = false,
  })
  if type(cwd) ~= "string" then return false end
  local new_cwd = cwd
  if cwd == "" then
    if type(self.__orig_cwd) ~= "string" or self.__orig_cwd:len() == 0 then
      new_cwd = nil
    else
      new_cwd = self.__orig_cwd
    end
  else
    local ok, v = pcall(vim.fn.expand, cwd)
    if not ok then
      util.error("Not a directory: " .. cwd)
      return false
    end
    cwd = v
    if vim.fn.isdirectory(cwd) ~= 1 then
      util.error("Not a directory: " .. cwd)
      return false
    end
  end
  if new_cwd == self.__orig_cwd then cwd = enum.NIL end
  storage.save(self.keywords, { cwd = cwd })
  self.cwd = new_cwd
  return true
end

function Task:delete_modifications()
  self.cmd = self.__orig_cmd
  self.env = vim.deepcopy(self.__orig_env or {})
  self.cwd = self.__orig_cwd
  storage.delete(self.keywords)
  return true
end

function Task:modified()
  if
    type(self.cmd) ~= type(self.__orig_cmd)
    or type(self.env) ~= type(self.__orig_env)
    or type(self.cwd) ~= type(self.__orig_cwd)
  then
    return true
  end
  if format_cmd(self.cmd) ~= format_cmd(self.__orig_cmd) then return true end
  if self.cwd ~= self.__orig_cwd then return true end
  if type(self.env) == "table" then
    for k, v in pairs(self.env) do
      if self.__orig_env[k] ~= v then return true end
    end
  end
  return false
end

---@param cmd string|table
---@return string
format_cmd = function(cmd)
  if cmd == nil then return "" end
  local cmd2 = {}
  if type(cmd) == "string" then cmd = vim.split(cmd, " ") end
  for _, v in ipairs(cmd) do
    if type(v) == "string" and v:len() > 0 then table.insert(cmd2, v) end
  end
  if #cmd2 == 0 then return "" end
  local s = table.concat(cmd2, " ")
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

return Task
