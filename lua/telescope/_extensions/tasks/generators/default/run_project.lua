local get_task_by_filetype

local get_gen = function()
  return require("telescope._extensions.tasks.model.generator"):new {
    opts = {
      name = "Run project Generator",
    },
    generator = get_task_by_filetype,
  }
end

local require_filetype_project_generator

get_task_by_filetype = function()
  local buf = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")

  local f = require_filetype_project_generator(filetype)
  if type(f) == "function" then
    return f(buf)
  elseif type(f) == "table" then
    return f
  end
  return nil
end

function require_filetype_project_generator(filetype)
  local name = "telescope._extensions.tasks.generators.default.run_project."
    .. filetype
  local ok, module = pcall(require, name)
  if not ok or not type(module) == "function" then
    return nil
  end
  return module
end

return get_gen()
