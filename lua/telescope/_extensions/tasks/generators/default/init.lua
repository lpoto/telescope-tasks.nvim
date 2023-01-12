local function require_generator_module(name)
  return function()
    return require("telescope._extensions.tasks.generators.default." .. name)
  end
end

return {
  ---Returns a hello world task generator.
  ---NOTE: this will be removed, as is only present for testing purposes.
  hello_world = require_generator_module "hello_world",
}
