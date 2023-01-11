local Default_generator =
  require "telescope._extensions.tasks.model.default_generator"

---@type Default_generator
local hello_world = setmetatable({
  name = "Hello World Generator",
}, Default_generator)

hello_world.generator_fn = function()
  return {
    "Hello world!",
    env = { HELLO_WORLD = "Hello World!" },
    cmd = "echo $HELLO_WORLD",
  }
end

return hello_world
