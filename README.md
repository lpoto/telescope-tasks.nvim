# Telescope tasks

`telescope-tasks.nvim` is a [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) extension,
that allows running custom synchronous tasks directly from the telescope prompt and displaying their
definitions and outputs in the telescope's previewer.

## Demo

https://user-images.githubusercontent.com/67372390/211383760-04a2a400-3557-4758-a510-922f6bc2d940.mp4

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
      output_window = "float", -- "vsplit" | "split" | "float"
      -- other telescope picker config fields
    },
  },
}

-- Load the tasks telescope extension
require("telescope").load_extension("tasks")
```

Add your tasks:

```lua
vim.g.telescope_tasks = vim.tbl_extend(
  "force", vim.g.telescope_tasks or {},
  {
    ["Run current Cargo binary"] = function()
      return {
        filetypes = { "rust" },
        patterns = { ".*/src/bin/[^/]+.rs" },
        cwd = find_root { ".git", "cargo.toml" },
        steps = {
          { "cargo", "run", "--bin", vim.fn.expand "%:p:t:r" },
        },
      }
    end,
    ["Run current Cargo project"] = function()
      return {
        filetypes = { "rust" },
        patterns = { ".*/src/.*.rs" },
        --ignore_patterns = { ".*/src/bin/[^/]+.rs" },
        cwd = find_root { ".git", "cargo.toml" },
        steps = {
          { "cargo", "run" },
        },
      }
    end,
  }
)
```

> This is the example used in the demo above.
>
> **_NOTE_**: See [Task Spec](#task-spec) for more on tasks' setup properties.

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

## Task Spec

| Property            | Type       | Description                                                                                                                                            |
| ------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **env**             | `table?`   | A table of environment variables used during the task's execution .                                                                                    |
| **clear_env**       | `boolean?` | When set to `true`, environment variables _not_ preset in the `env` table are cleared for the duration of the task's execution.                        |
| **cwd**             | `string?`  | A path to a directory that will be used as a working directory for the task.                                                                           |
| **filetypes**       | `table?`   | A table of filetypes that the task is available in, when `nil`, it is available in all filetypes.                                                      |
| **patterns**        | `table?`   | A table of lua patterns. The task is available only when this field is `nil` or the current filename matches one of the patterns.                      |
| **ignore_patterns** | `table?`   | A table of lua patterns. The task is available only when this field is `nil` or the current filename does not match any of the patterns in this table. |
| **steps**           | `table`    | A table of commands to execute. The commands may either be strings or tables of strings. There should always be at least one step.                     |

## Mappings

| Key     | Description                                                 |
| ------- | ----------------------------------------------------------- |
| `<CR>`  | Run the selected task, or kill it if it is already running. |
| `<C-o>` | Display the output of the selected task in another window.  |
| `<C-d>` | Delete the output of the selected task.                     |
| `<C-k>` | Scroll the previewer up.                                    |
| `<C-j>` | Scroll the previewer down.                                  |
