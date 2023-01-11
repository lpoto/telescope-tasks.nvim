local function require_generator_module(name)
  return function()
    local module = "telescope._extensions.tasks.generators.default"
    return require(module .. "." .. name):get_generator()
  end
end

return {
  ---Returns a hello world task generator.
  ---NOTE: this will be removed, as is only present for testing purposes.
  hello_world = require_generator_module "hello_world",
}
