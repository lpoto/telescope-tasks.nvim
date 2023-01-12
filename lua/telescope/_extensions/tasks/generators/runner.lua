local enum = require "telescope._extensions.tasks.enum"
local cache = require "telescope._extensions.tasks.generators.cache"

local should_run_generators

local runner = {}

runner.__current_generators = {}
runner.__adding = false

---provided, the currently available generators from the cache will be run.
---Runs all the available generators and returns the found tasks.
---@param generators table|nil: A table of generators to run.
---If not provided, all available generators are run.
---@param add boolean?: When true, generators will run even
---if the cache already exists, but the results will be added to the
---cache instead of overriding it.
---@param force boolean?: When true, the runner will run even if the
---generators are currently being added.
function runner.run(generators, add, force)
  if not force and runner.__adding then
    return
  end

  local ok, err = pcall(function()
    if
      not next(runner.__current_generators or {})
      or not should_run_generators()
    then
      return
    end
    local cached_tasks = nil
    if not add then
      cached_tasks = cache.get_for_current_context()
      if cached_tasks then
        return
      end
    end

    local found_tasks = {}

    for _, generator in ipairs(generators or runner.__current_generators or {}) do
      if generator:available() then
        found_tasks =
          vim.tbl_extend("force", found_tasks, generator:run() or {})
      end
    end

    if add then
      cache.add_to_current_context(found_tasks)
    else
      cache.set_for_current_context(found_tasks)
    end
  end)
  if not ok and type(err) == "string" then
    vim.notify(err, vim.log.levels.ERROR, {
      title = enum.TITLE,
    })
  end
end

---Create the BufEnter and DirChanged autocomands.
---These will run the generators.
function runner.init()
  vim.api.nvim_clear_autocmds {
    event = { "BufEnter", "DirChanged" },
    group = enum.TASKS_AUGROUP,
  }

  vim.api.nvim_create_autocmd("BufEnter", {
    group = enum.TASKS_AUGROUP,
    callback = function()
      runner.run()
    end,
  })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = enum.TASKS_AUGROUP,
    callback = function()
      runner.run()
    end,
  })
  if next(runner.__current_generators or {}) then
    runner.run(nil, true)
  end
end

---Checks whether the generators should be run in the current buffer.
---@return boolean: Whether the generators should be run
should_run_generators = function()
  local buf = vim.fn.bufnr()
  local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
  return buftype:len() == 0
end

return runner
