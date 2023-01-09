local enum = require "telescope._extensions.tasks.enum"
local setup = require "telescope._extensions.tasks.setup"

local create = {}

local handle_window
local determine_output_window_type

---@param buf number: A buffer number to create a window for
---@return number: A window id, -1 when invalid
function create.create_window(buf)
  local winnr = vim.fn.winnr()

  local ok, winid = pcall(determine_output_window_type(), buf)
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

  ok, err = pcall(
    vim.api.nvim_exec,
    "noautocmd keepjumps " .. winnr .. "wincmd w",
    false
  )
  if ok == false then
    vim.notify(err, vim.log.levels.ERROR, {
      title = enum.TITLE,
    })
  end
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

local function create_floating_window(buf)
  vim.notify("Floating window is not supported yet", vim.log.levels.WARN, {
    title = enum.TITLE,
  })
  return create_vsplit_window(buf)
end

---Highlight the texts added to the output term in the
---window identified by the provided winid
function create.set_highlights(winid)
  pcall(vim.api.nvim_win_call, winid, function()
    vim.fn.matchadd("Function", "^==> TASK: \\[\\_.\\{-}\\n\\n")
    vim.fn.matchadd("Constant", "^==> STEP: \\[\\_.\\{-}\\n\\n")
    vim.fn.matchadd("Comment", "^==> CWD: \\[\\_.\\{-}\\n\\n")
    vim.fn.matchadd("Statement", "^\\[Process exited .*\\]$")
    vim.fn.matchadd("Function", "^\\[Process exited 0\\]$")
  end)
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
  create.set_highlights(winid)
end

---@return function
determine_output_window_type = function()
  local win_type = setup.opts.output_window or "vsplit"
  if win_type == "vsplit" then
    return create_vsplit_window
  elseif win_type == "split" then
    return create_split_window
  elseif win_type == "floating"
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

return create
