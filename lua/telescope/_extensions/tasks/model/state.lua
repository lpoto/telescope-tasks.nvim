local scan = require "plenary.scandir"

---@class State
---@field iterated_subdirectories boolean
---@field found_files table
local State = {
  iterated_subdirectories = false,
  found_files = {},
}
State.__index = State

---@return State
function State:new()
  return setmetatable({}, State)
end

---@return table
function State:find_files()
  local cwd = vim.loop.cwd()
  if self.iterated_subdirectories == cwd then
    return self.found_files
  end
  self:__iterate_subdirectories()
  return self.found_files
end

function State:__iterate_subdirectories()
  local cwd = vim.loop.cwd()
  self.iterated_subdirectories = cwd
  self.found_files = {}
  scan.scan_dir(cwd, {
    hidden = false,
    add_dirs = false,
    on_insert = function(entry)
      if vim.fn.filereadable(entry) ~= 1 then
        return
      end
      local extension = vim.fn.fnamemodify(entry, ":e")
      if not extension or extension:len() == 0 then
        extension = vim.fn.fnamemodify(entry, ":t")
      else
        extension = extension:gsub("^.", "")
      end
      if not self.found_files[extension] then
        self.found_files[extension] = {}
      end
      table.insert(self.found_files[extension], entry)
    end,
  })
end

return State
