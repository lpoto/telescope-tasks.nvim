local get_task_by_filetype

local existing_run_project_generator_modules = {
  "go",
  -- "python", -- IN PROGRESS
  -- "cargo", -- IN PROGRESS
}

local get_gen = function()
  return require("telescope._extensions.tasks.model.generator"):new {
    opts = {
      name = "Run project Generator",
      experimental = true,
    },
    generator = get_task_by_filetype,
  }
end

local require_project_generator

get_task_by_filetype = function()
  local buf = vim.api.nvim_get_current_buf()

  local tasks = {}

  for _, module in ipairs(existing_run_project_generator_modules) do
    local f = require_project_generator(module)
    if type(f) == "function" then
      f = f(buf)
    end
    if type(f) == "table" then
      if f.cmd or f.name then
        f = { f }
      end
      tasks = vim.tbl_extend("force", tasks, f)
    end
  end

  if next(tasks or {}) == nil then
    return nil
  end
  return tasks
end

function require_project_generator(filetype)
  local name = "telescope._extensions.tasks.generators.default.run_project."
      .. filetype
  local ok, module = pcall(require, name)
  if not ok or not type(module) == "function" then
    return nil
  end
  return module
end

local function x() end

return get_gen()
