## DEFAULT GENERATORS

> The default generators are currently highly experimental and unfinished.
>
> Not many are added yet, and those added were not yet properly tested, hence
> custom generators are preffered at the moment.

**NOTE**: All of the functions in the tables bellow are exposed through the
`require('telescope').extensions.tasks.generators.default` API. To enable them,
pass one or more of the described functions to `tasks.generators.add(...)`.

## Added generators

### run_project

| Function               | Description                                                                                                                                                                                                                                                                                                                         |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `run_project.go()`     | When one of the current cwd or any of it's parent directories includes a `go.mod` file, tasks are generated for every file with the `main` package and the `main` function. If there is no `go.mod` file, but the current file is a `go` file with a `main` package and function, a task is generated for running the current file. |
| `run_project.python()` | Currently in progress...                                                                                                                                                                                                                                                                                                            |
| `run_project.cargo()`  | Currently in progress...                                                                                                                                                                                                                                                                                                            |
| `run_project.all()`    | Includes all of the run project generators above.                                                                                                                                                                                                                                                                                   |
