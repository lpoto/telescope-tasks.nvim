local finder = require "telescope._extensions.tasks.picker.finder"
local previewer = require "telescope._extensions.tasks.picker.previewer"
local mappings = require "telescope._extensions.tasks.picker.mappings"

local pickers = require "telescope.pickers"
local conf = require("telescope.config").values

local available_tasks_telescope_picker = function(options)
  local buf = vim.api.nvim_get_current_buf()
  local tasks_finder = finder.available_tasks_finder(buf, true)
  if not tasks_finder then
    return
  end

  local function tasks_picker(opts)
    opts = opts or {}
    local picker = pickers.new(opts, {
      prompt_title = "Tasks",
      results_title = "Available Tasks",
      finder = tasks_finder,
      sorter = conf.generic_sorter(opts),
      previewer = previewer.task_previewer(),
      dynamic_preview_title = true,
      selection_strategy = "row",
      scroll_strategy = "cycle",
      attach_mappings = mappings.attach_mappings,
    })
    picker.starting_buffer = buf
    picker:find()
  end

  vim.defer_fn(function()
    tasks_picker(options)
  end, 0)
end

return function(opts)
  available_tasks_telescope_picker(opts)
end
