local Default = require "telescope._extensions.tasks.model.default_generator"

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
    __meta = {
      name = "python_run_file_" .. name:gsub("/", "_"):gsub("\\", "-"),
    },
  }
  if type(vim.g.PYTHON_ENV) == "table" and next(vim.g.PYTHON_ENV) then
    t.env = vim.g.PYTHON_ENV
  end
  return t
end

return python
