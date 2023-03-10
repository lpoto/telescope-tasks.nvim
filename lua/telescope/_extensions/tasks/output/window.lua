local enum = require "telescope._extensions.tasks.enum"
local util = require "telescope._extensions.tasks.enum"
local setup = require "telescope._extensions.tasks.setup"
local highlight = require "telescope._extensions.tasks.output.highlight"
local float = require "telescope._extensions.tasks.output.float"
local executor = require "telescope._extensions.tasks.executor"

local window = {}

local handle_window
local determine_output_window_type
local add_autocmd
local close_win

---@param buf number: A buffer number to create a window for
---@rarapm title string?: The title of the window, relevant only for floats
---@return number: A window id, -1 when invalid
function window.create(buf, title)
  title = title or "Terminal"

  local ok, winid = pcall(determine_output_window_type(), buf, title)
  if ok == false then
    util.error(winid)
    return -1
  end
  if not vim.api.nvim_win_is_valid(winid) then
    util.error "Failed to create a window"
    return -1
  end

  local ok2, err = pcall(handle_window, winid)
  if ok2 == false and type(err) == "string" then
    util.error(err)
  end

  add_autocmd(buf)

  return winid
end

local function create_vsplit_window(buf)
  local winid = vim.fn.win_getid(vim.fn.winnr())

  vim.fn.execute("noautocmd keepjumps vertical sb " .. buf, false)

  if vim.fn.winwidth(winid) < 50 and vim.o.columns >= 70 then
    -- NOTE: make sure the output window is at least 50 columns wide
    vim.api.nvim_exec("vertical resize " .. 50, false)
  end
  return vim.fn.win_getid(vim.fn.winnr())
end

local function create_split_window(buf)
  vim.fn.execute("noautocmd keepjumps sb " .. buf, false)

  return vim.fn.win_getid(vim.fn.winnr())
end

local function set_options(winid)
  vim.api.nvim_win_set_option(winid, "wrap", true)
  vim.api.nvim_win_set_option(winid, "number", false)
  vim.api.nvim_win_set_option(winid, "number", false)
  vim.api.nvim_win_set_option(winid, "relativenumber", false)
  vim.api.nvim_win_set_option(winid, "signcolumn", "no")
  vim.api.nvim_win_set_option(winid, "statusline", "")
end

handle_window = function(winid)
  set_options(winid)
  highlight.set_output_window_highlights(winid)
end

---@return function
determine_output_window_type = function()
  local win_type = setup.opts.output and setup.opts.output.style or "float"

  if win_type == "vsplit"
      or win_type == "vertical"
      or win_type == "vertical split"
  then
    return create_vsplit_window
  elseif win_type == "split" or win_type == "normal" then
    return create_split_window
  elseif win_type == "floating"
      or win_type == "float"
      or win_type == "popup"
  then
    return float.create
  else
    util.error("Invalid window type:", win_type)
  end
  return create_vsplit_window
end

add_autocmd = function(buf)
  vim.api.nvim_clear_autocmds {
    event = { "BufLeave" },
    buffer = buf,
    group = enum.TASKS_AUGROUP,
  }
  vim.api.nvim_create_autocmd("BufLeave", {
    group = enum.TASKS_AUGROUP,
    buffer = buf,
    once = true,
    callback = function()
      local wid = vim.fn.bufwinid(buf)
      if not wid or wid == -1 or not vim.api.nvim_win_is_valid(wid) then
        return
      end
      close_win(buf)
    end,
  })

  vim.keymap.set("n", "q", function()
    close_win(buf)
  end, {
    buffer = buf,
  })
  vim.keymap.set("n", "<C-q>", function()
    local task = executor.get_task_from_buffer(buf)
    if not task then
      return
    end
    executor.to_qf(task)
  end, {
    buffer = buf,
  })
end

close_win = function(buf)
  local wid = vim.fn.bufwinid(buf)
  if not wid or wid == -1 or not vim.api.nvim_win_is_valid(wid) then
    return
  end
  vim.api.nvim_win_close(wid, false)
end

return window
