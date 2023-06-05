# Telescope tasks

`telescope-tasks.nvim` is a [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) extension,
that allows running tasks directly from the telescope prompt and displaying their
definitions and outputs in the telescope's previewer.

## Demo

https://github.com/lpoto/telescope-tasks.nvim/assets/67372390/bf527ce3-602c-4d7a-9563-b5c1290f7113

## Installation

The extension may be installed manually or with a plugin manager of choice.

An example using [Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
require("lazy").setup({
  "lpoto/telescope-tasks.nvim",
})
```

## Setup and usage

First setup and load the extension:

```lua
require("telescope").setup {
  extensions = {
    -- NOTE: this setup is optional
    tasks = {
      theme = "ivy",
      output = {
        style = "float", -- "split" | "float" | "tab"
        layout = "center", -- "left" | "right" | "center" | "below" | "above"
        scale = 0.4, -- output window to editor size ratio
        -- NOTE: scale and "center" layout are only relevant when style == "float"
      },
      -- other picker setup values
    },
  },
}
-- Load the tasks telescope extension
require("telescope").load_extension "tasks"
```

See [Generators](#generators) on how to generate tasks.

Then use the extension:

```lua
:Telescope tasks
```

or in lua:

```lua
require("telescope").extensions.tasks.tasks()
```

> **_NOTE_**: See [Mappings](#mappings) for the default mappings in the tasks prompt

The last opened output may then be toggled with:

```lua
 require("telescope").extensions.tasks.actions.toggle_last_output()
```

## Generators

You may either use the [Default Generators](./DEFAULT_GENERATORS.md), or add [Custom Generators](./CUSTOM_GENERATORS.md).

## Mappings

| Key        | Description                                                     |
| ---------- | --------------------------------------------------------------- |
| `<CR>`     | Run the selected task, or kill it if it is already running.     |
| `<C-o>`    | Display the output of the selected task in another window.      |
| `e`        | Edit the selected task's associated file (only in normal mode). |
| `<C-r>`    | Remove the output of the selected task.                         |
| `<C-a>`    | Modify the selected task's command.                             |
| `<C-e>`    | Modify the selected task's environment variables.               |
| `<C-c>`    | Modify the selected task's working directory.                   |
| `<C-x>`    | Delete the task's modifications.                                |
| `<C-u>`    | Scroll the previewer up.                                        |
| `<C-d>`    | Scroll the previewer down.                                      |
| `<C-q>`    | Send a task's output to quickfix.                               |
| `o`        | same as `<C-o>` but only in normal mode.                        |
| `r` or `d` | same as `<C-r>` but only in normal mode.                        |
