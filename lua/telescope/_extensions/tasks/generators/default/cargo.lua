local util = require "telescope._extensions.tasks.util"
local Path = require "plenary.path"
local Default_generator =
  require "telescope._extensions.tasks.model.default_generator"

---Check if there exists a Cargo.toml file, if not return nil.
---Check targets in Cargo.toml and build tasks from them.
---If a binary is currently opened, add a task for running the binary.
---
---TODO: handle adding cargo.toml targets tasks!
---
---cargo run [options] [-- args]
---
---NOTE: this returns only tasks for running rust with cargo
local cargo = Default_generator:new {
  errorformat = [[%Eerror: %\%%(aborting %\|could not compile%\)%\@!%m,]]
    .. [[%Eerror[E%n]: %m,]]
    .. [[%Inote: %m,]]
    .. [[%Wwarning: %\%%(%.%# warning%\)%\@!%m,]]
    .. [[%C %#--> %f:%l:%c,]]
    .. [[%E  left:%m,%C right:%m %f:%l:%c,%Z,]]
    .. [[%.%#panicked at \'%m\'\, %f:%l:%c]],
  opts = {
    name = "Default Cargo Generator",
    experimental = true,
  },
}

function cargo.generator()
  if not util.parent_dir_includes { "Cargo.toml" } then
    return nil
  end
  local cwd = util.find_current_file_root { "Cargo.toml" }
  local tasks = {}
  if
    vim.fn.expand "%:p:h" == Path:new(cwd):joinpath("src", "bin"):__tostring()
  then
    local file = vim.fn.expand "%:p"
    local tail = vim.fn.expand "%:p:t:r"
    local cmd = {
      "cargo",
      "run",
      "--bin",
      tail,
    }
    local binary_task = {
      name = "Run current Cargo binary",
      cmd = cmd,
      cwd = cwd,
      __meta = {
        "cargo",
        "binary",
        file,
      },
    }
    if type(vim.g.CARGO_ENV) == "table" and next(vim.g.CARGO_ENV) then
      binary_task.env = vim.g.CARGO_ENV
    end
    table.insert(tasks, binary_task)
  end
  if next(tasks or {}) then
    return tasks
  end
  return nil
end

return cargo
