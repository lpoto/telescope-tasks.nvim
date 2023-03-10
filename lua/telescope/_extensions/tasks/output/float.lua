local setup = require "telescope._extensions.tasks.setup"

local float = {}

local get_centered_opts
local get_bottom_opts
local get_right_opts
local get_left_opts

function float.create(buf, title)
  local opts = {
    relative = "editor",
    focusable = true,
    title_pos = "center",
    noautocmd = true,
    --border = "rounded",
    border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
    style = "minimal",
  }
  if title then
    opts.title = " " .. title .. " "
  end

  local scale = setup.opts.output and setup.opts.output.scale
  if type(scale) ~= "number" or scale < 0.1 or scale > 1.5 then
    scale = 0.4
  end

  local layout = setup.opts.output and setup.opts.output.layout
  local f
  if layout == "bottom" or layout == "down" or layout == "bottom_pane" then
    f = get_bottom_opts
  elseif layout == "left" or layout == "left_pane" then
    f = get_left_opts
  elseif layout == "right" or layout == "right_pane" then
    f = get_right_opts
  else
    f = get_centered_opts
  end

  opts = vim.tbl_extend("force", opts, f(vim.o.lines, vim.o.columns, scale))

  return vim.api.nvim_open_win(buf, true, opts)
end

get_centered_opts = function(lines, columns, scale)
  local pref_w = math.floor(columns * scale)
  local w = math.max(math.min(pref_w, columns), 12)
  local h = math.max(lines - 5, 12)

  local row = 1
  local col = (columns - w) / 2
  if columns % 2 ~= 0 then
    col = col - 1
  end
  if w == columns then
    col = 0
  end
  if h == lines then
    row = 0
  end

  return {
    width = w,
    height = h,
    row = row,
    col = col,
  }
end

get_bottom_opts = function(lines, columns, scale)
  local h = math.min(math.max(20, math.floor(lines * scale)), lines / 2)

  return {
    width = columns,
    height = h,
    row = lines,
    col = 0,
    border = { "", "─", "", "", "", "", "", "" },
    anchor = "SW",
  }
end

get_left_opts = function(lines, columns, scale)
  local w = math.min(math.max(20, math.floor(columns * scale)), columns / 2)
  if w > 100 then
    w = 100
  end

  return {
    width = w,
    height = lines,
    row = 0,
    col = 0,
    border = { "", " ", "│", "│", "│", " ", "", "" },
    anchor = "NW",
  }
end

get_right_opts = function(lines, columns, scale)
  local w = math.min(math.max(20, math.floor(columns * scale)), columns / 2)
  if w > 100 then
    w = 100
  end

  return {
    width = w,
    height = lines,
    row = 0,
    col = columns,
    border = { "│", " ", "", "", "", " ", "│", "│" },
    anchor = "NE",
  }
end

return float
