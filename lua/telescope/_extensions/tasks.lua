local enum = require "telescope._extensions.tasks.enum"
local picker = require "telescope._extensions.tasks.picker"
local setup = require "telescope._extensions.tasks.setup"
local actions = require "telescope._extensions.tasks.actions"
local generators = require "telescope._extensions.tasks.generators"

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

---Opens the tasks picker and merges the provided opts
---with the default options provided during the setup.
---@param opts table|nil
local function tasks(opts)
  opts = opts or {}
  picker(vim.tbl_extend("force", setup.opts, opts))
end

-- NOTE: create the augroup used by the plugin
vim.api.nvim_create_augroup(enum.TASKS_AUGROUP, { clear = true })
-- NOTE: Initialize the generators
generators.__init()

-- NOTE: register the extension
return telescope.register_extension {
  setup = setup.setup,
  exports = {
    tasks = tasks,
    actions = actions,
    generators = generators,
    _picker = picker,
  },
}
