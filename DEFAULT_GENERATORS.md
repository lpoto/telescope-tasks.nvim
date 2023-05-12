## DEFAULT GENERATORS

> The default generators are currently highly experimental and unfinished.
>
> Not many are added yet, and those added were not yet properly tested, hence
> custom generators are preffered at the moment.

The default generators API is exposed through:

```lua
local default = require('telescope').extensions.tasks.generators.default
```

To enable all of them, use:

```lua
default.all()
```

Call any of the functions described bellow to enable just some of them.

## Available default generators

| Function           | Description                                                                                                                                                               |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `default.go()`     | Finds all Go projects in subdirectories and generates tasks for running or building them. If no `go.mod` file is found, generates a task for running the current Go file. |
| `default.lua()`    | Generates a task for running a current lua file.                                                                                                                          |
| `default.cargo()`  | Currently in progress ...                                                                                                                                                 |
| `default.python()` | Currently in progress ...                                                                                                                                                 |
