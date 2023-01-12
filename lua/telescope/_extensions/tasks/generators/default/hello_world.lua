return require("telescope._extensions.tasks.model.default_generator"):new {
  name = "Hello World Generator",
  generator_fn = function()
    return {
      "Hello world!",
      env = { HELLO_WORLD = "Hello World!" },
      cmd = "echo $HELLO_WORLD",
    }
  end,
}
