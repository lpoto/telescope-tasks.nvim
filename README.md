# Telescope tasks

`telescope-tasks.nvim` is a [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) extension,
that allows running custom tasks directly from the telescope prompt and displaying their
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

Currently only custom generators are supported. Example generator used in the [demo](#demo) above:

```lua
require("telescope").extensions.tasks.generators.add(function(buf)
    return {
        "Run current Cargo binary",
        cwd = find_root {"cargo.toml"},
        cmd = {"cargo", "run", "--bin", vim.fn.expand "%:p:t:r"}

      }
    -- NOTE: multiple tasks may be returned at once
    -- NOTE: You may return nil aswell in case you want to add custom
    -- conditions to the generator function itself
end, {
  name = "Custom Cargo binary task generator",
  filetypes = {"rust"},
  patterns = { ".*/src/bin/[^/]+.rs"}
})

require("telescope").extensions.tasks.generators.add(function(buf)
    return {
        "Run current Cargo project",
        cwd = find_root {"cargo.toml"},
        cmd = {"cargo", "run"}
    }
end, {
  filetypes = {"rust"},
  -- ignore_patterns = { ".*/src/bin/[^/]+.rs"}
})
```

> _NOTE_ See [Task Spec](#task-spec) for the details on tasks' properties.

**_NOTE_** In the future, default generators will be available that will auto generate
tasks from the current project's config files.

> Example: _cargo.toml_ targets or _package.json_ scripts

## Task Spec

| Property          | Type                | Description                                                                        |
| ----------------- | ------------------- | ---------------------------------------------------------------------------------- |
| **name** or `[1]` | `string`            | The name of the task.                                                              |
| **cmd**           | `string` or `table` | A command to be executed. When a table, the first element should be an executable. |
| **env**           | `table?`            | A table of environment variables used during the task's execution .                |
| **cwd**           | `string?`           | A path to a directory that will be used as a working directory for the task.       |

## Mappings

| Key     | Description                                                 |
| ------- | ----------------------------------------------------------- |
| `<CR>`  | Run the selected task, or kill it if it is already running. |
| `<C-o>` | Display the output of the selected task in another window.  |
| `<C-d>` | Delete the output of the selected task.                     |
| `<C-k>` | Scroll the previewer up.                                    |
| `<C-j>` | Scroll the previewer down.                                  |

## [Roadmap](./ROADMAP.md)
