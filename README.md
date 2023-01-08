# Telescope tasks

`telescope-tasks.nvim` is a [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) extension,
that allows running custom synchronous tasks directly from the telescope prompt and displaying their
definitions and outputs in the telescope's previewer.

## Demo

https://user-images.githubusercontent.com/67372390/211212163-be52df2b-dfe1-4b72-91c1-b5909543c4aa.mp4

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

First load the extension:

```lua
require("telescope").load_extension("tasks")
```

Add your tasks:

```lua
-- NOTE: This is the task used in the demo above
vim.g.telescope_tasks = vim.tbl_extend(
  "force", vim.g.telescope_tasks or {},
  {
    -- tasks should always be functions, as they
    -- are called immediately before being executed,
    -- so the fields may be dynamic
    ["Run current Python file"] = function()
      env = {}, -- A table of environment variables (optional)
      clear_env = false, -- If true, the environment will be cleared before running the task, and only values from `env` will be kept (optional)
      cwd = nil, -- A valid path to set as the working directory for the task (optional)
      filetypes = {"python"}, -- A table of filetypes that the task should be available in (optional)
      patterns = {}, -- A table of lua patterns, the task is available only in files matching one of the patterns (optional)
      ignore_patterns = {}, -- A table of lua patterns, the task is available only in files not matching any of the patterns (optional)
      steps = { -- A table of steps to execute in order
        {"python3", vim.api.nvim_buf_get_name(0)} -- This could also be a single string
      }
    end
  }
)
```

Then use the extension:

```lua
:Telescope tasks
```

or in lua:

```lua
require("telescope").extensions.tasks.tasks()
```

> **_NOTE_**: Additional configurations or themes may be passed to the picker.
>
> ```lua
> require("telescope").extensions.tasks.tasks(require("telescope.themes").get_ivy())
> -- or :Telescope tasks theme=ivy
> ```

## Roadmap

- [x] Display currently available tasks in a telescope picker
- [x] Allow running and killing tasks from the telescope picker
- [x] Show tasks' definitions or output(when available) in the telescope previewer
- [x] Allow opening the task's output in a separate buffer
- [x] Allow toggling the latest output
- [ ] Add setup
  - [ ] Allow setting a theme in config
  - [ ] Allow custom mappings
  - [ ] Allow configuring output window
- [ ] Redo tasks execution so that each step is it's own job
