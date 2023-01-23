local Generator = require "telescope._extensions.tasks.model.generator"
local runner = require "telescope._extensions.tasks.generators.runner"

local default = {}
local add_generator

---Enable all default generators
function default.all()
  return default.go(), default.cargo(), default.python()
end

---Enable Go default generator
function default.go()
  return add_generator(
    require "telescope._extensions.tasks.generators.default.go"
  )
end

---Enable Cargo default generator
function default.cargo()
  return add_generator(
    require "telescope._extensions.tasks.generators.default.cargo"
  )
end

---Enable Python generator
function default.python()
  return add_generator(
    require "telescope._extensions.tasks.generators.default..python"
  )
end

add_generator = function(generator_fn)
  local gen = Generator:new {
    opts = {
      name = "Run project Generator",
      experimental = true,
    },
    generator = generator_fn,
  }
  runner.add_generators { gen }
end

return default
