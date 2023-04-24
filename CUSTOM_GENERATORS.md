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

custom.add {
  generator = function(buf)
    return {
        "Example Task",
        cwd = util.find_current_file_root {".bashrc"},
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
--- You may pass multiple generators at once ( `custom.add({...}, {...}, {...})` )
```

## Generator Spec

| Property      | Type       | Description                                                                                                            |
| ------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------- |
| **generator** | `function` | The generator function that recieves buffer number as input and returns nil or one or more [Task](#task-spec) objects. |
| **opts**      | `table?`   | [Generator Opts](#generator-opts-spec).                                                                                |

## Generator Opts Spec

| Property                    | Type      | Description                                                                                                                                                              |
| --------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **name**                    | `string?` | The name of the generator.                                                                                                                                               |
| **filetypes**               | `table?`  | A table of filetypes in which the generator will be run.                                                                                                                 |
| **patterns**                | `table?`  | A table lua patterns. The generator will only be run when the current filename matches **_at least one_** pattern.                                                       |
| **ignore_patterns**         | `table?`  | A table lua patterns. The generator will only be run when the current filename **_does not_** match any patterns.                                                        |
| **parent_dir_includes**     | `table?`  | A table of filenames and directory names. The generator will only run when one of the current file's parent directories includes one of the listed files or directories. |
| **parent_dir_not_includes** | `table?`  | A table of filenames and directory names. The generator will only run when none of the current file's parent directories include any of the listed files or directories. |

## Task Spec

| Property           | Type                | Description                                                                                                                                                                                         |
| ------------------ | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **name** or `[1]`  | `string`            | The name of the task.                                                                                                                                                                               |
| **cmd**            | `string` or `table` | A command to be executed. When a table, the first element should be an executable.                                                                                                                  |
| **env**            | `table?`            | A table of environment variables used during the task's execution .                                                                                                                                 |
| **cwd**            | `string?`           | A path to a directory that will be used as a working directory for the task.                                                                                                                        |
| **errorformat**    | `string?`           | The errorformat used when sending the output to quickfix.                                                                                                                                           |
