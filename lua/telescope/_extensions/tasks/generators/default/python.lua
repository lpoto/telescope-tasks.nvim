local Default = require "telescope._extensions.tasks.model.default_generator"
local util = require "telescope._extensions.tasks.util"

---Add a task for running the current python file.
---
---TODO: handle `venv`.
local python = Default:new {
  errorformat = '%C\\ %.%#,%A\\ \\ File\\ "%f"\\,'
    .. "\\ line\\ %l%.%#,%Z%[%^\\ ]%\\@=%m",
  opts = {
    name = "Default Python Generator",
    experimental = true,
  },
}

function python.generator(buf)
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  if filetype ~= "python" then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(buf)

  local cmd = {
    "python",
    name,
  }
  local t = {
    "Run current Python file",
    cmd = cmd,
    filename = name,
    keywords = {
      "python",
      name,
    },
  }
  local env = util.get_env "python"
  if type(env) == "table" and next(env) then
    t.env = env
  end
  return t
end

return python
