local enum = require("telescope-tasks.enum")
local util = require("telescope-tasks.util")
local setup = require("telescope-tasks.setup")
local highlight = require("telescope-tasks.output.highlight")
local float = require("telescope-tasks.output.float")
local executor = require("telescope-tasks.executor")

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

  local layout = setup.opts.output and setup.opts.output.layout

  local ok, winid = pcall(determine_output_window_type(), buf, title, layout)
  if ok == false then
    util.error(winid)
    return -1
  end
  if not vim.api.nvim_win_is_valid(winid) then
    util.error("Failed to create a window")
    return -1
  end

  local ok2, err = pcall(handle_window, winid)
  if ok2 == false and type(err) == "string" then
    util.error(err)
  end

  add_autocmd(buf)

  return winid
end

local function create_split_window(buf, _, layout)
  if
    layout == enum.OUTPUT.LAYOUT.BOTTOM or layout == enum.OUTPUT.LAYOUT.TOP
  then
    local splitbelow = vim.api.nvim_get_option("splitbelow")

    if layout == enum.OUTPUT.LAYOUT.BOTTOM then
      vim.api.nvim_set_option("splitbelow", true)
    else
      vim.api.nvim_set_option("splitbelow", false)
    end

    vim.fn.execute("noautocmd keepjumps sb " .. buf, false)

    vim.api.nvim_set_option("splitbelow", splitbelow)
  else
    local winid = vim.fn.win_getid(vim.fn.winnr())
    local splitright = vim.api.nvim_get_option("splitright")

    if layout == enum.OUTPUT.LAYOUT.RIGHT then
      vim.api.nvim_set_option("splitright", true)
    else
      vim.api.nvim_set_option("splitright", false)
    end
    vim.fn.execute("noautocmd keepjumps vertical sb " .. buf, false)

    vim.api.nvim_set_option("splitright", splitright)

    if vim.fn.winwidth(winid) < 50 and vim.o.columns >= 70 then
      -- NOTE: make sure the output window is at least 50 columns wide
      vim.api.nvim_exec("vertical resize " .. 50, false)
    end
  end

  return vim.fn.win_getid(vim.fn.winnr())
end

local function create_tab_window(buf)
  vim.fn.execute("noautocmd keepjumps tab sb " .. buf, false)

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

  if win_type == enum.OUTPUT.STYLE.SPLIT then
    return create_split_window
  elseif win_type == enum.OUTPUT.STYLE.TAB then
    return create_tab_window
  end
  return float.create
end

add_autocmd = function(buf)
  vim.api.nvim_clear_autocmds({
    event = { "BufLeave" },
    buffer = buf,
    group = enum.TASKS_AUGROUP,
  })
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
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
