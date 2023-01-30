# Telescope tasks

`telescope-tasks.nvim` is a [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) extension,
that allows running tasks directly from the telescope prompt and displaying their
definitions and outputs in the telescope's previewer.

## Demo

https://user-images.githubusercontent.com/67372390/212735801-5dcbecc1-5d2e-4ce5-894e-fba731b3d05a.mp4

> The demo uses the default `run_project` generator for `Go` and `Python` projects.

## Installation

### Packer

```lua
use {"lpoto/telescope-tasks.nvim"}
```

### Vim-Plug

```lua
Plug  "lpoto/telescope-tasks.nvim"
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
        style = "float", -- "vsplit" | "split" | "float"
        layout = "center", -- "bottom" | "left" | "right" | "center"
        scale = 0.4, -- output window to editor size ratio
        -- NOTE: layout and scale are only relevant when style == "float"
      },
      -- Directory to store the modified commands data to.
      -- Set it to false to disable saving modified commands.
      data_dir = Path:new(vim.fn.stdpath "data", "telescope_tasks"))
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

| Key     | Description                                                 |
| ------- | ----------------------------------------------------------- |
| `<CR>`  | Run the selected task, or kill it if it is already running. |
| `<C-o>` | Display the output of the selected task in another window.  |
| `<C-d>` | Delete the output of the selected task.                     |
| `<C-k>` | Scroll the previewer up.                                    |
| `<C-j>` | Scroll the previewer down.                                  |
| `<C-q>` | Send a task's output to quickfix.                           |
