local previewers = require "telescope.previewers"
local executor = require "telescope._extensions.tasks.executor"
local highlights = require "telescope._extensions.tasks.highlight"
local enum = require "telescope._extensions.tasks.enum"

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
    preview_fn = preview_fn,
  }
end

scroll_fn = function(self, direction)
  local ok, e = pcall(function()
    if not self.state then
      return
    end

    local winid = self.state.winid
    local n = vim.api.nvim_win_get_height(winid)
    n = direction < 0 and -n or n
    local lines = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(winid))
    local pos = vim.api.nvim_win_get_cursor(winid)
    local cur_y, cur_x = pos[1], pos[2]

    local new_y = cur_y + direction
    cur_y = (new_y <= 0) and lines or (new_y > lines) and 1 or new_y
    vim.api.nvim_win_set_cursor(winid, { cur_y, cur_x })
  end)
  if not ok and type(e) == "string" then
    vim.notify(e, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
  end
end

local function display_running_buf(status, task)
  if executor.buffer_is_to_be_deleted(task.name) then
    return false
  end
  local running_buf = executor.get_task_output_buf(task.name)
  if running_buf and vim.api.nvim_buf_is_valid(running_buf) then
    vim.api.nvim_win_set_buf(status.preview_win, running_buf)
    return true
  end
  return false
end

local function display_definition_buf(status, task)
  previewer.old_preview_buf = vim.api.nvim_create_buf(false, true)
  pcall(
    vim.api.nvim_buf_set_lines,
    previewer.old_preview_buf,
    0,
    -1,
    false,
    task:to_yaml_definition()
  )
  pcall(
    vim.api.nvim_buf_set_option,
    previewer.old_preview_buf,
    "syntax",
    "yaml"
  )
  local ok, e = pcall(
    vim.api.nvim_win_set_buf,
    status.preview_win,
    previewer.old_preview_buf
  )
  if ok == false then
    log.error(e)
  end
end

preview_fn = function(self, entry, status)
  vim.notify "PREVIER"
  highlights.set_previewer_highlights(status.preview_win)
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
