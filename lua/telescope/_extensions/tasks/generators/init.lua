local enum = require "telescope._extensions.tasks.enum"
local cache = require "telescope._extensions.tasks.generators.cache"
local Task = require "telescope._extensions.tasks.model.task"

local current_generators = {}
local current_tasks = {}
local should_run_on_add = false
local run_generators
local should_run_generators
local should_run_generators_on_dir_change
local should_run_generators_on_buf_win_enter

local generators = {}

---@param g function: A generators functin that receives a
--buffer number as input and returns a table of tasks or nil
function generators.add(g)
  if type(g) ~= "function" then
    vim.notify("Generator must be a function", enum.log_level.WARN, {
      title = enum.TITLE,
    })
    return
  end
  table.insert(current_generators, {
    name = "Custom",
    f = g,
  })

  if should_run_on_add then
    should_run_on_add = false
    if should_run_generators() then
      run_generators()
    end
  end
end

---Fetch all currently available tasks.
---
---@return table: All current tasks
function generators.__get_tasks()
  return current_tasks
end

---@param name string: name of the task
---@return Task|nil: The task with the provided name
function generators.__get_task_by_name(name)
  return current_tasks[name]
end

function generators.__init()
  vim.api.nvim_clear_autocmds {
    event = { "BufEnter", "DirChanged" },
    group = enum.TASKS_AUGROUP,
  }

  vim.api.nvim_create_autocmd("BufEnter", {
    group = enum.TASKS_AUGROUP,
    callback = function()
      if should_run_generators_on_buf_win_enter() then
        run_generators()
      end
    end,
  })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = enum.TASKS_AUGROUP,
    callback = function()
      if should_run_generators_on_dir_change() then
        run_generators()
      end
    end,
  })
  if cache.is_empty() then
    should_run_on_add = true
  else
    if should_run_generators() then
      run_generators()
    end
  end
end

run_generators = function()
  local cached_tasks = cache.get_for_current_context()
  if cached_tasks then
    current_tasks = cached_tasks
    return
  end

  local found_tasks = {}

  for _, g in ipairs(current_generators) do
    local ok, tasks = pcall(g.f, vim.fn.bufnr())
    if not ok and type(tasks) == "string" then
      vim.notify(tasks, vim.log.levels.ERROR, {
        title = enum.TITLE,
      })
    elseif type(tasks) == "table" then
      if tasks.name or tasks.cmd or tasks.env then
        tasks = { tasks }
      end
      for _, o in pairs(tasks) do
        local task, err = Task.__create(o, g.name)
        if err ~= nil then
          vim.notify(err, vim.log.levels.WARN, {
            title = enum.TITLE,
          })
        else
          found_tasks[task.name] = task
        end
      end
    end
  end

  if next(found_tasks) ~= nil then
    current_tasks = cache.set_for_current_context(found_tasks)
  end
end

local function __should_run_generators()
  local buf = vim.fn.bufnr()

  local buftype = vim.api.nvim_buf_get_option(buf, "buftype")

  return not vim.tbl_contains({
    "nofile",
    "prompt",
    "terminal",
    "help",
    "quickfix",
  }, buftype)
end

should_run_generators = function()
  return __should_run_generators()
end

should_run_generators_on_buf_win_enter = function()
  return __should_run_generators()
end

should_run_generators_on_dir_change = function()
  return __should_run_generators()
end

return generators
