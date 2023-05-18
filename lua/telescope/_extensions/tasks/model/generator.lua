local util = require "telescope._extensions.tasks.util"
local Task = require "telescope._extensions.tasks.model.task"
local Generator_opts =
  require "telescope._extensions.tasks.model.generator_opts"

---@class Generator
---@field generator function
---@field opts Generator_opts
local Generator = {
  name = "Custom",
}
Generator.__index = Generator

---@param o table|function
---@return Generator
function Generator:new(o)
  if type(o) == "function" then
    o = { generator = o }
  end
  assert(type(o) == "table", "Generator should be a table")
  local generator = setmetatable(o or {}, Generator)
  assert(
    type(generator.generator) == "function",
    "Generator should have a function `generator` field"
  )
  if not generator.opts then
    return generator
  end

  generator.opts = Generator_opts:new(generator.opts)
  local name = generator.opts.name or generator.name

  generator.name = name
  generator.opts.name = name

  return generator
end

---@return boolean: Whether the generator is available in
---the current context
function Generator:available()
  if not self.opts then
    return false
  end
  return self.opts:check_in_current_context()
end

---Runs the generator function, and notifies any
---errors.
---@return table|nil:  A table of Task objects
function Generator:run()
  local buf = vim.api.nvim_get_current_buf()
  local ok, tasks = pcall(self.generator, buf)
  if not ok and type(tasks) == "string" then
    util.error(tasks)
    return nil
  elseif type(tasks) ~= "table" then
    if tasks ~= nil then
      util.error "Genrator should return a table"
    end
    return nil
  end
  if tasks.name or tasks.cmd or tasks.env then
    tasks = { tasks }
  end
  local found_tasks = {}
  for _, o in pairs(tasks) do
    local err
    ok, err = pcall(function()
      local task = Task:new(o, self.opts)
      found_tasks[task.name] = task
    end)
    if not ok and type(err) == "string" then
      util.warn(err)
    end
  end
  return found_tasks
end

return Generator
