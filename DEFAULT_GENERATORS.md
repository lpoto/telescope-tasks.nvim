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

| Function                   | Description                                                                                                                                                               |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `default.makefile()`       | Finds all makefiles in subdirectories and generates tasks for all targets.                                                                                                |
| `default.package_json()`   | Finds all package.json files in subdirectories and generates tasks for all scripts.                                                                                       |
| `default.docker_compose()` | Finds all docker-compose files in subdirectories and generates tasks for them.                                                                                            |
| `default.go()`             | Finds all Go projects in subdirectories and generates tasks for running or building them. If no `go.mod` file is found, generates a task for running the current Go file. |
| `default.maven()`          | Finds all pom.xml files with `<build>` tag and generates tasks for building them.                                                                                         |
| `default.lua()`            | Generates a task for running a current lua file.                                                                                                                          |
| `default.cargo()`          | Finds Cargo.toml files and generates tasks for the package and defined binaries.                                                                                          |
| `default.python()`         | Finds \_\_main\_\_.py files and generates tasks for running them. Also generates a task for currently opened python file.                                                 |
