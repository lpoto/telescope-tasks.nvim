return require("telescope._extensions.tasks.model.generator"):new {
  opts = {
    name = "Hello World Generator",
  },
  generator = function()
    return {
      "Hello world!",
      env = { HELLO_WORLD = "Hello World!" },
      cmd = "echo $HELLO_WORLD",
    }
  end,
}
