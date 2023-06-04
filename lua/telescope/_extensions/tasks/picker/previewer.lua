local previewers = require "telescope.previewers"
local executor = require "telescope._extensions.tasks.executor"
local highlight = require "telescope._extensions.tasks.output.highlight"
local util = require "telescope._extensions.tasks.util"

local previewer = {}

local scroll_fn
local teardown_fn
local preview_fn

---Creates a new telescope previewer for the tasks.
---If a task is running or has an output, the previewr
---displayes the output, otherwise it displays the task's definition
---@return table: a telescope previewer
function previewer.task_previewer()
  return previewers.new {
    title = "Task Preview",
    dynamic_title = function(_, entry)
      local running_buf = executor.get_task_output_buf(entry.value.name)
      if running_buf and vim.api.nvim_buf_is_valid(running_buf) then
        return "Task Output"
      end
      return "Task Definition"
    end,
    scroll_fn = scroll_fn,
    teardown = teardown_fn,
    preview_fn = function(self, entry, status)
      preview_fn(self, entry, status)
    end,
  }
end

scroll_fn = function(self, direction)
  local ok, e = pcall(function()
    if not self.state then
      return
    end

    local winid = self.state.winid
    local n = vim.api.nvim_win_get_height(winid)
    n = math.min(math.max(math.ceil(n / 2), 5), 15)
    if direction < 0 then
      n = -n
    end
    local pos = vim.api.nvim_win_get_cursor(winid)
    local cur_y, cur_x = pos[1], pos[2]

    local new_y = cur_y + n
    -- ignore error that may occur if new_y out of range
    pcall(vim.api.nvim_win_set_cursor, winid, { new_y, cur_x })
  end)
  if not ok and type(e) == "string" then
    util.warn(e)
  end
end

local function display_running_buf(status, task)
  if executor.buffer_is_to_be_deleted(task.name) then
    return false
  end
  local running_buf = executor.get_task_output_buf(task.name)
  if running_buf and vim.api.nvim_buf_is_valid(running_buf) then
    vim.api.nvim_win_set_buf(status.preview_win, running_buf)
    vim.api.nvim_win_set_cursor(
      status.preview_win,
      { vim.api.nvim_buf_line_count(running_buf), 0 }
    )
    return true
  end
  return false
end

local function display_definition_buf(status, task)
  previewer.old_preview_buf = vim.api.nvim_create_buf(false, true)
  local def = task:get_definition()
  local lines = {}
  for _, item in ipairs(def) do
    if type(item) == "table" then
      if not next(item) then
        table.insert(lines, "")
      else
        if item.value == nil then
          table.insert(lines, item.key)
        else
          table.insert(lines, item.key .. ": " .. item.value)
        end
      end
    end
  end
  pcall(
    vim.api.nvim_buf_set_lines,
    previewer.old_preview_buf,
    0,
    -1,
    false,
    lines
  )
  pcall(
    vim.api.nvim_buf_set_option,
    previewer.old_preview_buf,
    "buftype",
    "nofile"
  )
  pcall(
    vim.api.nvim_buf_set_option,
    previewer.old_preview_buf,
    "bufhidden",
    "wipe"
  )
  for i, item in ipairs(def) do
    if type(item) == "table" and next(item) then
      local key_hl = "Conditional"
      local value_hl = "Normal"
      if item.key:match "^#" then
        key_hl = "Comment"
        value_hl = "Comment"
      end
      local n = vim.fn.strchars(item.key)
      vim.api.nvim_buf_add_highlight(
        previewer.old_preview_buf,
        -1,
        key_hl,
        i - 1,
        0,
        n
      )
      vim.api.nvim_buf_add_highlight(
        previewer.old_preview_buf,
        -1,
        value_hl,
        i - 1,
        n + 2,
        -1
      )
    end
  end
  local ok, e = pcall(
    vim.api.nvim_win_set_buf,
    status.preview_win,
    previewer.old_preview_buf
  )
  if ok == false then
    util.error(e)
  end
end

preview_fn = function(self, entry, status)
  highlight.set_previewer_highlights(status.preview_win)
  local old_buf = previewer.old_preview_buf

  if not display_running_buf(status, entry.value) then
    display_definition_buf(status, entry.value)
  end

  if old_buf ~= nil and vim.api.nvim_buf_is_valid(old_buf) then
    pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
  end

  self.status = status
  self.state = self.state or {}
  self.state.winid = status.preview_win
  self.state.bufnr = vim.api.nvim_win_get_buf(status.preview_win)
end

teardown_fn = function(self)
  self.state = nil
  pcall(vim.api.nvim_buf_delete, previewer.old_preview_buf, { force = true })
  if self.status == nil or self.status.preview_win == nil then
    return
  end
  local winid = self.status.preview_win
  if
    type(winid) ~= "number"
    or winid == -1
    or not vim.api.nvim_win_is_valid(winid)
  then
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.cmd "noautocmd"
  vim.api.nvim_win_set_buf(winid, buf)
end

return previewer
