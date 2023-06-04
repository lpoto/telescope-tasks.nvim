## CUSTOM GENERATORS

The custom generators API is exposed through:

```lua
local custom = require('telescope').extensions.tasks.generators.custom
```

To add a custom generator, pass one or more [Generator](#generator-spec) objects
to the following function:

```lua
custom.add(...)
```

An example:

```lua
local util = require("telescope").extensions.tasks.util

custom.add(
  function(buf)
    local root = util.find_current_file_root { "Makefile" }
    return {
        "Example Task",
        cwd = root,
        filename = root .. "/Makefile",
        cmd = { "make", "example" },
        -- env = {...}
        keywords = {
            "makefile",
            root,
            "example",
        }
      }
    -- NOTE: multiple tasks may be returned at once
    -- NOTE: You may return nil aswell in case you want to add custom
    -- conditions to the generator function itself
  end
)
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
