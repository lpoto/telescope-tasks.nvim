## DEFAULT GENERATORS

> _NOTE_ The default generators are currently highly experimental and unfinished.
>
> Not many are added yet, and those added were not yet properly tested, hence
> custom generators are preffered at the moment.

## Added generators

| Name          | Description                                                                    |
| ------------- | ------------------------------------------------------------------------------ |
| `run_project` | Generates tasks based on the current project. See [Run project](#run-project). |

## Run Project

The `run_project` is currently available for the following filetypes/projects:

| Name | Description                                                                                                                                                                                                                                                                           |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Go` | When one of the current file's parent directories includes a `go.mod` file, tasks are generated for every file with the `main` package. Otherwise if there is not `go.mod` but the current file is a go file with a `main` package, a task is generated for running the current file. |
