## CUSTOM GENERATORS

The custom generators API is exposed through:

```lua
local custom = require('telescope').extensions.tasks.generators.custom
```

To add a custom generator, pass one or more generators
to the following function:

```lua
custom.add(...)
```

> **_NOTE_**: The generators are just functions returning nil, a single task or a table of tasks.

An example:

```lua
local tasks = require('telescope').extensions.tasks

tasks.generators.custom.add(function(buf)
    local filename = vim.api.nvim_buf_get_name(buf)
    local extension = vim.fn.fnamemodify(filename, ":e")
    local tail = vim.fn.fnamemodify(filename, ":t:r")
    if extension ~= "c" then
      -- Generate this task only for C files
      return nil
    end

    return {
      "Run current C file",
      filename = filename,
      cwd = tasks.util.find_current_file_root { ".git" },
      cmd = ("gcc -o %s.out %s && ./%s.out"):format(tail, filename, tail),
    }
    -- NOTE: multiple tasks may be returned aswell
end)
--- You may pass multiple generators at once ( `custom.add(g1, g2, ...)` )
```

## Task Spec

| Property          | Type                | Description                                                                                                   |
| ----------------- | ------------------- | ------------------------------------------------------------------------------------------------------------- |
| **name** or `[1]` | `string`            | The name of the task.                                                                                         |
| **cmd**           | `string` or `table` | A command to be executed. When a table, the first element should be an executable.                            |
| **env**           | `table?`            | A table of environment variables used during the task's execution .                                           |
| **cwd**           | `string?`           | A path to a directory that will be used as a working directory for the task.                                  |
| **errorformat**   | `string?`           | The errorformat used when sending the output to quickfix.                                                     |
| **filename**      | `string?`           | A filename associated with the task (using `e` mapping will open this file).                                  |
| **keywords**      | `string[]?`         | A table of strings that uniquely describe the task (this will be used to store the task's modified commands). |
