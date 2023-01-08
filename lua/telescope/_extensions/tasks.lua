local enum = require "telescope._extensions.tasks.enum"
local picker = require "telescope._extensions.tasks.picker"
local finder = require "telescope._extensions.tasks.finder"

-- NOTE: ensure the telescope is loaded
-- before registering the extension
local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  vim.notify(
    "This extension requires telescope.nvim "
      .. "(https://github.com/nvim-telescope/telescope.nvim)",
    log.levels.error,
    {
      title = enum.TITLE,
    }
  )
end

-- NOTE: create the augroup used by the plugin
vim.api.nvim_create_augroup(enum.TASKS_AUGROUP, { clear = true })

-- NOTE: register the extension
return telescope.register_extension {
  exports = {
    tasks = picker.available_tasks_picker,
    finder = finder.available_tasks_finder,
    _picker = picker.available_tasks_picker,
  },
}
