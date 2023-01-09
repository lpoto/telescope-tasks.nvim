local enum = require "telescope._extensions.tasks.enum"

local setup = {}

setup.opts = {}

---Creates the default picker options from the provided
---options. If the `theme` field with a string value is added,
---the telescope theme identified by that value is added to the options.
---@param opts table
function setup.setup(opts)
  if type(opts.theme) == "string" then
    local theme = require("telescope.themes")["get_" .. opts.theme]
    if theme == nil then
      vim.notify(
        "No such telescope theme: '" .. opts.theme .. "'",
        vim.log.levels.WARN,
        {
          title = enum.TITLE,
        }
      )
    else
      opts = theme(opts)
    end
    setup.opts = vim.tbl_extend("force", setup.opts, opts)
  end
end

return setup
