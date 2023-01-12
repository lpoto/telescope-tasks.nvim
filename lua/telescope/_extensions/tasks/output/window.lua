local enum = require "telescope._extensions.tasks.enum"
local setup = require "telescope._extensions.tasks.setup"
local highlight = require "telescope._extensions.tasks.output.highlight"

local window = {}

local handle_window
local determine_output_window_type
local add_autocmd
local clean_buffer
local close_win

---@param buf number: A buffer number to create a window for
---@rarapm title string?: The title of the window, relevant only for floats
---@return number: A window id, -1 when invalid
function window.create(buf, title)
  clean_buffer(buf)

  local ok, winid = pcall(determine_output_window_type(), buf, title)
  if ok == false then
    vim.notify(winid, vim.log.levels.ERROR, {
      title = enum.TITLE,
    })
    return -1
  end
  if not vim.api.nvim_win_is_valid(winid) then
    vim.notify("Failed to create a window", vim.log.levels.ERROR, {
      title = enum.TITLE,
    })
    return -1
  end

  local ok2, err = pcall(handle_window, winid)
  if ok2 == false and type(err) == "string" then
    vim.notify(err, vim.log.levels.ERROR, {
      title = enum.TITLE,
    })
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

local function create_floating_window(buf, title)
  local width = vim.o.columns
  local height = vim.o.lines

  local w = math.min(80, width - 4)
  local h = height - 4

  local row = (height - h) / 2
  local col = (width - w) / 2
  if title ~= nil then
    title = " " .. title .. " "
  end

  if title ~= nil and title:len() > w - 2 and title:len() > 5 then
    title = title:sub(0, w - 5) .. "..."
  end

  local winid = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = row,
    col = col,
    focusable = true,
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
    noautocmd = true,
  })

  vim.keymap.set("n", "q", function()
    close_win(buf)
  end, {
    buffer = buf,
  })

  return winid
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

clean_buffer = function(buf)
  pcall(vim.keymap.del, "n", "q", { buffer = buf })
end

---@return function
determine_output_window_type = function()
  local win_type = setup.opts.output_window
    or setup.opts.output_win
    or setup.opts.win
    or setup.opts.window
    or "float"

  if
    win_type == "vsplit"
    or win_type == "vertical"
    or win_type == "vertical split"
  then
    return create_vsplit_window
  elseif win_type == "split" or win_type == "normal" then
    return create_split_window
  elseif
    win_type == "floating"
    or win_type == "float"
    or win_type == "popup"
  then
    return create_floating_window
  else
    vim.notify("Invalid window type: " .. win_type, vim.log.levels.ERROR, {
      title = enum.TITLE,
    })
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
end

close_win = function(buf)
  local wid = vim.fn.bufwinid(buf)
  if not wid or wid == -1 or not vim.api.nvim_win_is_valid(wid) then
    return
  end
  vim.api.nvim_win_close(wid, false)
end

return window
