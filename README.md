# Telescope tasks

`telescope-tasks.nvim` is a [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) extension,
that allows running custom tasks directly from the telescope prompt and displaying their
definitions and outputs in the telescope's previewer.

## Demo

https://user-images.githubusercontent.com/67372390/212438209-183b6fb0-7f7a-4d47-839b-9a3f1f05ed16.mp4

> The demo uses the default `run_project` generator and the custom generator from the [Example](#custom-generators).

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

> _NOTE_ The default generators are currently highly experimental and unfinished.
> Not many are added yet, and those added were not yet properly tested, hence
> [Custom Generators][#custom-generators] are preffered at the moment.
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

## Roadmap

- [x] Display tasks in a telescope picker
  - [x] Display tasks' definitions in a previewer
  - [x] Display tasks' output in a previewer, when available
- [x] Expose API for adding custom task generators
- [x] Enable default generators
  - [x] Support changing variables used by the default generators
  - [ ] Add generators for running the current project based on filetype
