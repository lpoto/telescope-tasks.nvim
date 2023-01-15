local create_generator

local run_project = {}

function run_project.all()
  return run_project.go(), run_project.cargo(), run_project.python()
end

function run_project.go()
  return create_generator(
    require "telescope._extensions.tasks.generators.default.run_project.go"
  )
end

function run_project.cargo()
  return create_generator(
    require "telescope._extensions.tasks.generators.default.run_project.cargo"
  )
end

function run_project.python()
  return create_generator(
    require "telescope._extensions.tasks.generators.default.run_project.python"
  )
end

create_generator = function(generator_fn)
  return require("telescope._extensions.tasks.model.generator"):new {
    opts = {
      name = "Run project Generator",
      experimental = true,
    },
    generator = generator_fn,
  }
end

return run_project
