local enum = require "telescope._extensions.tasks.enum"
local finder = require "telescope._extensions.tasks.picker.finder"
local executor = require "telescope._extensions.tasks.executor"
local previewer = require "telescope._extensions.tasks.picker.previewer"
local mappings = require "telescope._extensions.tasks.picker.mappings"
local cache = require "telescope._extensions.tasks.generators.cache"

local pickers = require "telescope.pickers"
local conf = require("telescope.config").values

local available_tasks_telescope_picker = function(options)
  local tasks = cache.get_current_tasks()

  if
    next(tasks or {}) == nil
    and next(executor.get_running_tasks() and {}) == nil
  then
    vim.notify("There are no available tasks", vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return -1
  end

  local function tasks_picker(opts)
    opts = opts or {}
    pickers
      .new(opts, {
        prompt_title = "Tasks",
        results_title = "Available Tasks",
        finder = finder.available_tasks_finder(),
        sorter = conf.generic_sorter(opts),
        previewer = previewer.task_previewer(),
        dynamic_preview_title = true,
        selection_strategy = "row",
        scroll_strategy = "cycle",
        attach_mappings = mappings.attach_mappings,
      })
      :find()
  end

  vim.defer_fn(function()
    tasks_picker(options)
  end, 0)
end

return function(opts)
  available_tasks_telescope_picker(opts)
end
