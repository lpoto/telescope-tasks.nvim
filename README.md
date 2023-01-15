# Telescope tasks

`telescope-tasks.nvim` is a [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) extension,
that allows running tasks directly from the telescope prompt and displaying their
definitions and outputs in the telescope's previewer.

The tasks may either be [auto-generated](#generators) based on the current project, or added with [custom generators](#custom-generators).

> Note that auto-generating is still in progress and experimental.

## Demo

https://user-images.githubusercontent.com/67372390/212492248-72411619-525f-4e65-b702-b602e42dc4ce.mp4

> The demo uses the default `run_project` generator for `Go` and python projects.

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
  generators.default.run_project(),
  -- ...
}
```

> _NOTE_ see [DEFAULT_GENERATORS](./DEFAULT_GENERATORS.md) to see the currently
> implemented default generators.
>
> The default generators build their tasks from the [ENV](./lua/telescope/_extensions/tasks/generators/env.lua) variables.
> These may be modified by setting the `extensions.tasks.env` field in the setup.

## Custom Generators

Example custom generator:

```lua
local tasks = require("telescope").extensions.tasks

tasks.generators.add {
  generator = function(buf)
    return {
        "Example Task",
        cwd = tasks.util.find_current_file_root {".bashrc"},
        cmd = {"cat", ".bashrc"}
        -- env = {...}
      }
    -- NOTE: multiple tasks may be returned at once
    -- NOTE: You may return nil aswell in case you want to add custom
    -- conditions to the generator function itself
  end,
  opts = {
    name = "Example Custom Generator",
    filetypes = {"python", "sh"},
    patterns = { os.getenv("HOME") .. "/.*"},
  }
}
---Multiple generators may be added at once with `tasks.generators.add_batch`
```

> _NOTE_ See [Task Spec](#task-spec) for the details on tasks' properties.

> _NOTE_ See [Generator Opts](#generator-opts) for the details on generators' options.

## Task Spec

| Property          | Type                | Description                                                                        |
| ----------------- | ------------------- | ---------------------------------------------------------------------------------- |
| **name** or `[1]` | `string`            | The name of the task.                                                              |
| **cmd**           | `string` or `table` | A command to be executed. When a table, the first element should be an executable. |
| **env**           | `table?`            | A table of environment variables used during the task's execution .                |
| **cwd**           | `string?`           | A path to a directory that will be used as a working directory for the task.       |

## Generator Opts

| Property                    | Type      | Description                                                                                                                                                              |
| --------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **name**                    | `string?` | The name of the generator.                                                                                                                                               |
| **filetypes**               | `table?`  | A table of filetypes in which the generator will be run.                                                                                                                 |
| **patterns**                | `table?`  | A table lua patterns. The generator will only be run when the current filename matches **_at least one_** pattern.                                                       |
| **ignore_patterns**         | `table?`  | A table lua patterns. The generator will only be run when the current filename **_does not_** match any patterns.                                                        |
| **parent_dir_includes**     | `table?`  | A table of filenames and directory names. The generator will only run when one of the current file's parent directories includes one of the listed files or directories. |
| **parent_dir_not_includes** | `table?`  | A table of filenames and directory names. The generator will only run when none of the current file's parent directories include any of the listed files or directories. |

## Mappings

| Key     | Description                                                 |
| ------- | ----------------------------------------------------------- |
| `<CR>`  | Run the selected task, or kill it if it is already running. |
| `<C-o>` | Display the output of the selected task in another window.  |
| `<C-d>` | Delete the output of the selected task.                     |
| `<C-k>` | Scroll the previewer up.                                    |
| `<C-j>` | Scroll the previewer down.                                  |
