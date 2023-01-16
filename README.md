# Telescope tasks

`telescope-tasks.nvim` is a [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) extension,
that allows running tasks directly from the telescope prompt and displaying their
definitions and outputs in the telescope's previewer.

The tasks may either be [auto-generated](#generators) based on the current project, or added with [custom generators](#custom-generators).

> Note that auto-generating is still in progress and experimental.

## Demo

https://user-images.githubusercontent.com/67372390/212492248-72411619-525f-4e65-b702-b602e42dc4ce.mp4

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

> When there is no output available, a terminal will be opened.

## Generators

You may either use the [Default Generators](./DEFAULT_GENERATORS.md), or add [Custom Generators](./CUSTOM_GENERATORS.md).

## Mappings

| Key     | Description                                                 |
| ------- | ----------------------------------------------------------- |
| `<CR>`  | Run the selected task, or kill it if it is already running. |
| `<C-a>` | Run the selected task with arguments.                       |
| `<C-o>` | Display the output of the selected task in another window.  |
| `<C-d>` | Delete the output of the selected task.                     |
| `<C-k>` | Scroll the previewer up.                                    |
| `<C-j>` | Scroll the previewer down.                                  |
