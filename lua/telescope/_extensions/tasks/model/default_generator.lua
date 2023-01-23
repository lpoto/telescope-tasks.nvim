local Generator = require "telescope._extensions.tasks.model.generator"
local runner = require "telescope._extensions.tasks.generators.runner"

---@class Default_generator
---@field errorformat string
---@field generator function: A generator function
---@field opts Generator_opts: The generator opts
local Default_generator = {}
Default_generator.__index = Default_generator

---@return Default_generator
function Default_generator:new(o)
  assert(
    type(o) == "table",
    "Default_generator should be created from a table"
  )
  assert(
    type(o.errorformat) == "string",
    "Default_generator should have a string errorformat field"
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
            table.insert(_tasks, task)
          end
        end
      end
      return _tasks
    end,
    opts = self.opts,
  }
  runner.add_generators { generator }
end

return Default_generator
