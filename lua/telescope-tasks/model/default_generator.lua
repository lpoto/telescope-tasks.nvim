local Generator = require "telescope-tasks.model.generator"
local runner = require "telescope-tasks.generators.runner"
local health = require "telescope-tasks.health"

---@class Default_generator
---@field errorformat string
---@field generator function: A generator function
---@field healthcheck function?
---@field on_load function?
local Default_generator = {}
Default_generator.__index = Default_generator

---@return Default_generator
function Default_generator:new(o)
  assert(
    type(o) == "table",
    "Default_generator should be created from a table"
  )
  return setmetatable(o or {}, Default_generator)
end

---@return State|nil
function Default_generator:state()
  return runner.get_state()
end

function Default_generator:load()
  local generator = Generator:new {
    generator = function(buf)
      local tasks = self.generator(buf)
      local _tasks = {}
      if next(tasks or {}) then
        if tasks.cmd or tasks.cwd or tasks.env or tasks.name then
          tasks = { tasks }
        end
        for _, task in ipairs(tasks) do
          if task ~= nil then
            task.errorformat = self.errorformat
            task.__default_generator = true
            task.__experimental = true
            table.insert(_tasks, task)
          end
        end
      end
      return _tasks
    end,
  }
  runner.add_generators { generator }

  if self.on_load then
    self.on_load()
  end

  if type(self.healthcheck) == "function" then
    health.__add_check(self.healthcheck)
  end
end

return Default_generator
