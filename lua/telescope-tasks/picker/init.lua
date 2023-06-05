local finder = require "telescope-tasks.picker.finder"
local previewer = require "telescope-tasks.picker.previewer"
local mappings = require "telescope-tasks.picker.mappings"
local enum = require "telescope-tasks.enum"

local pickers = require "telescope.pickers"
local conf = require("telescope.config").values

local available_tasks_telescope_picker = function(options)
  local buf = vim.api.nvim_get_current_buf()
  local tasks_finder = finder.available_tasks_finder(buf, true, true)
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

    -- NOTE: this is so we may swap between
    -- output buffers and the tasks picker without
    -- errors
    vim.api.nvim_exec_autocmds("BufLeave", {
      group = enum.TASKS_AUGROUP,
    })

    picker:find()
  end

  vim.defer_fn(function()
    tasks_picker(options)
  end, 0)
end

return function(opts)
  available_tasks_telescope_picker(opts)
end
