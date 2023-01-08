local previewers = require "telescope.previewers"
local executor = require "telescope._extensions.tasks.executor"
local create = require "telescope._extensions.tasks.window.task_output.create"

local previewer = {}

local quote_string
local get_task_definition

---Creates a new telescope previewer for the tasks.
---If a task is running or has an output, the previewr
---displayes the output, otherwise it displays the task's definition
---@return table: a telescope previewer
function previewer.task_previewer()
  return previewers.new {
    teardown = function(self)
      pcall(
        vim.api.nvim_buf_delete,
        previewer.old_preview_buf,
        { force = true }
      )
      local _, winid = pcall(vim.fn.bufwinid, self.state.bufnr)
      self.state.bufnr = nil
      if
        type(winid) ~= "number"
        or winid == -1
        or not vim.api.nvim_win_is_valid(winid)
      then
        return
      end
      local buf = vim.api.nvim_create_buf(false, true)
      pcall(vim.api.nvim_win_set_buf, winid, buf)
    end,
    preview_fn = function(self, entry, status)
      create.set_highlights(status.preview_win)
      local running_buf = executor.get_task_output_buf(entry.value.name)
      local old_buf = previewer.old_preview_buf
      if running_buf and vim.api.nvim_buf_is_valid(running_buf) then
        vim.api.nvim_win_call(status.preview_win, function()
          vim.api.nvim_win_set_buf(status.preview_win, running_buf)
        end)
      else
        previewer.old_preview_buf = vim.api.nvim_create_buf(false, true)
        pcall(
          vim.api.nvim_buf_set_lines,
          previewer.old_preview_buf,
          0,
          -1,
          false,
          get_task_definition(entry.value)
        )
        pcall(
          vim.api.nvim_buf_set_option,
          previewer.old_preview_buf,
          "filetype",
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
      if old_buf ~= nil and vim.api.nvim_buf_is_valid(old_buf) then
        vim.api.nvim_buf_delete(old_buf, { force = true })
      end

      self.state = self.state or {}
      self.state.bufnr = vim.api.nvim_win_get_buf(status.preview_win)
    end,
    dynamic_title = function(_, entry)
      local running_buf = executor.get_task_output_buf(entry.value.name)
      if running_buf and vim.api.nvim_buf_is_valid(running_buf) then
        return entry.value.name .. " (output)"
      end
      return entry.value.name .. " (definition)"
    end,
  }
end

quote_string = function(v)
  if
    type(v) == "string"
    and (string.find(v, "'") or string.find(v, "`") or string.find(v, '"'))
  then
    if string.find(v, "'") == nil then
      v = "'" .. v .. "'"
    elseif string.find(v, '"') == nil then
      v = '"' .. v .. '"'
    elseif string.find(v, "`") == nil then
      v = "`" .. v .. "`"
    end
  end
  return v
end

get_task_definition = function(task)
  local def = {}
  if task.name ~= nil then
    table.insert(def, "name: " .. quote_string(task.name))
  end
  local function generate(tbl, indent)
    if not indent then
      indent = 0
    end
    for k, v in pairs(tbl) do
      if k ~= "name" then
        v = quote_string(v)
        if type(k) == "number" then
          k = "- "
        else
          k = k .. ": "
        end
        local formatting = string.rep("  ", indent) .. k
        if type(v) == "table" then
          table.insert(def, formatting)
          generate(v, indent + 1)
        elseif type(v) == "boolean" then
          table.insert(def, formatting .. tostring(v))
        else
          table.insert(def, formatting .. v)
        end
      end
    end
  end

  generate(task, 0)
  return def
end

return previewer
