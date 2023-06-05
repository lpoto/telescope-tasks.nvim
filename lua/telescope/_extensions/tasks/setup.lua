local util = require "telescope._extensions.tasks.util"
local enum = require "telescope._extensions.tasks.enum"

local setup = {}

setup.opts = {
  output = {
    style = "float", -- "split" | "vsplit" | "tab" | "float"
    layout = "center", -- "bottom" | "left" | "right"
    scale = 0.4,
  },
}

local parse_output_opts
local errors = nil

---Creates the default picker options from the provided
---options. If the `theme` field with a string value is added,
---the telescope theme identified by that value is added to the options.
---@param opts table
function setup.setup(opts)
  errors = {}
  if type(opts) ~= "table" then
    local msg = "Tasks config should be a table!"
    table.insert(errors, msg)
    util.warn(msg)
    return
  end

  local output_opts = setup.opts.output
  if opts.output then
    output_opts =
      vim.tbl_extend("force", output_opts, parse_output_opts(opts.output))
  end

  if type(opts.theme) == "string" then
    local theme = require("telescope.themes")["get_" .. opts.theme]
    if theme == nil then
      local msg = "No such telescope theme: '" .. opts.theme .. "'"
      table.insert(errors, msg)
      util.warn(msg)
    else
      opts = theme(opts)
    end
  end
  opts.output = output_opts
  setup.opts = vim.tbl_extend("force", setup.opts, opts)
end

function setup.get_errors()
  return errors
end

function parse_output_opts(opts)
  if not errors then
    errors = {}
  end
  local o = {}
  if opts.scale ~= nil then
    if type(opts.scale) ~= "number" or opts.scale < 0.1 or opts.scale > 1 then
      local msg = "'scale' should be a number between 0.1 and 1"
      table.insert(errors, msg)
      util.warn(msg)
    else
      o.scale = opts.scale
    end
  end
  if opts.style ~= nil then
    if type(opts.style) ~= "string" then
      local msg = "'style' should be a string"
      table.insert(errors, msg)
      util.warn(msg)
    else
      if opts.style == "tab" or opts.style == "tabpage" then
        o.style = enum.OUTPUT.STYLE.TAB
      elseif
        opts.style == "split"
        or opts.style == "horizontal"
        or opts.style == "normal"
      then
        o.style = enum.OUTPUT.STYLE.SPLIT
      elseif
        opts.style == "vsplit"
        or opts.style == "vertical"
        or opts.style == "vertical split"
        or opts.style == "v split"
      then
        o.style = enum.OUTPUT.STYLE.VSPLIT
      elseif
        opts.style == "float"
        or opts.style == "floating"
        or opts.style == "popup"
      then
        o.style = enum.OUTPUT.STYLE.FLOAT
      else
        local msg = "Unknown output style: '" .. opts.style .. "'"
        table.insert(errors, msg)
        util.warn(msg)
      end
      o.style = opts.style
    end
  end
  if opts.layout ~= nil then
    if type(opts.layout) ~= "string" then
      local msg = "'layout' should be a string"
      table.insert(errors, msg)
      util.warn(msg)
    else
      if
        opts.layout == "center"
        or opts.layout == "centre"
        or opts.layout == "middle"
      then
        o.layout = enum.OUTPUT.LAYOUT.CENTER
      elseif
        opts.layout == "bottom"
        or opts.layout == "down"
        or opts.layout == "below"
        or opts.layout == "bellow"
        or opts.layout == "bottom_pane"
        or opts.layout == "bottom pane"
      then
        o.layout = enum.OUTPUT.LAYOUT.BOTTOM
      elseif
        opts.layout == "top"
        or opts.layout == "up"
        or opts.layout == "above"
        or opts.layout == "top_pane"
        or opts.layout == "top pane"
      then
        o.layout = enum.OUTPUT.LAYOUT.TOP
      elseif
        opts.layout == "left"
        or opts.layout == "left_pane"
        or opts.layout == "left pane"
      then
        o.layout = enum.OUTPUT.LAYOUT.LEFT
      elseif
        opts.layout == "right"
        or opts.layout == "right_pane"
        or opts.layout == "right pane"
      then
        o.layout = enum.OUTPUT.LAYOUT.RIGHT
      else
        local msg = "Unknown output layout: '" .. opts.layout .. "'"
        table.insert(errors, msg)
        util.warn(msg)
      end
    end
  end
  return o
end

return setup
