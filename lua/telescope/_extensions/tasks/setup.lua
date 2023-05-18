local util = require "telescope._extensions.tasks.util"
local enum = require "telescope._extensions.tasks.enum"
local Path = require "plenary.path"

local setup = {}

setup.opts = {
  output = {
    style = "float", -- "split" | "vsplit" | "tab" | "float"
    layout = "center", -- "bottom" | "left" | "right"
    scale = 0.4,
  },
  data_dir = Path:new(vim.fn.stdpath "data", "telescope_tasks"):__tostring(),
}

local parse_output_opts

---Creates the default picker options from the provided
---options. If the `theme` field with a string value is added,
---the telescope theme identified by that value is added to the options.
---@param opts table
function setup.setup(opts)
  if type(opts) ~= "table" then
    util.warn "Tasks config should be a table!"
    return
  end

  local output_opts = setup.opts.output
  if opts.output then
    output_opts =
      vim.tbl_extend("force", output_opts, parse_output_opts(opts.output))
  end
  if opts.data_dir then
    if type(opts.data_dir) ~= "string" then
      util.warn "'data_dir' should be a string"
      opts.data_dir = nil
    end
  end

  if type(opts.theme) == "string" then
    local theme = require("telescope.themes")["get_" .. opts.theme]
    if theme == nil then
      util.warn("No such telescope theme: '" .. opts.theme .. "'")
    else
      opts = theme(opts)
    end
  end
  opts.output = output_opts
  setup.opts = vim.tbl_extend("force", setup.opts, opts)
end

function parse_output_opts(opts)
  local o = {}
  if opts.scale ~= nil then
    if type(opts.scale) ~= "number" or opts.scale < 0.1 or opts.scale > 1 then
      util.warn "'scale' should be a number between 0.1 and 1"
    else
      o.scale = opts.scale
    end
  end
  if opts.style ~= nil then
    if type(opts.style) ~= "string" then
      util.warn "'style' should be a string"
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
        util.warn("Unknown output style: '" .. opts.style .. "'")
      end
      o.style = opts.style
    end
  end
  if opts.layout ~= nil then
    if type(opts.layout) ~= "string" then
      util.warn "'layout' should be a string"
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
        util.warn("Unknown output layout: '" .. opts.layout .. "'")
      end
    end
  end
  return o
end

return setup
