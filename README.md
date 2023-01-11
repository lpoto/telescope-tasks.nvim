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

The generators api is exposed through:

```lua
local generators = require("telescope").extensions.tasks.generators
```

Enable all default generators with:

```lua
generators.enable_default()
```

Or cherry pick some default generators:

```lua
generators.add_batch {
  generators.default.hello_world(),
  -- ...
}
```

> _NOTE_ Currenlty only the hello world default generator is
> available, but it will be removed later as it is used only for testing purposes.
>
> Instead, other generators will be added in the future. For example, generating
> tasks from _cargo.toml_ targets or _package.json_ scripts.

## Custom Generators

Example generators used in the [demo](#demo) above:

```lua
local tasks = require("telescope").extensions.tasks

tasks.generators.add {
  generator = function(buf)
    return {
        "Run current Cargo binary",
        cwd = tasks.util.find_current_file_root {"cargo.toml"},
        cmd = {"cargo", "run", "--bin", vim.fn.expand "%:p:t:r"}

      }
    -- NOTE: multiple tasks may be returned at once
    -- NOTE: You may return nil aswell in case you want to add custom
    -- conditions to the generator function itself
  end,
  opts = {
    name = "Custom Cargo binary task generator",
    filetypes = {"rust"},
    patterns = { ".*/src/bin/[^/]+.rs"}
  }
}

tasks.generators.add(function(buf)
    return {
        "Run current Cargo project",
        cwd = tasks.util.find_current_file_root {"cargo.toml"},
        cmd = {"cargo", "run"}
    }
end)
```

> _NOTE_ See [Task Spec](#task-spec) for the details on tasks' properties.

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
