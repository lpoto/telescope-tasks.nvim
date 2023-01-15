local runner = require "telescope._extensions.tasks.generators.runner"
local Generator = require "telescope._extensions.tasks.model.generator"

local add_generator

local run_project = {}

---Enable all run_project generators
function run_project.all()
  return run_project.go(), run_project.cargo(), run_project.python()
end

---Enable Go run_project generator
function run_project.go()
  return add_generator(
    require "telescope._extensions.tasks.generators.default.run_project.go"
  )
end

---Enable Cargo run_project generator
function run_project.cargo()
  return add_generator(
    require "telescope._extensions.tasks.generators.default.run_project.cargo"
  )
end

---Enable Python run_project generator
function run_project.python()
  return add_generator(
    require "telescope._extensions.tasks.generators.default.run_project.python"
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

return run_project
