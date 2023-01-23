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
  if self.iterated_subdirectories then
    return self.found_files
  end
  self:__iterate_subdirectories()
  return self.found_files
end

function State:__iterate_subdirectories()
  self.iterated_subdirectories = true
  self.found_files = {}
  scan.scan_dir(vim.loop.cwd(), {
    hidden = false,
    add_dirs = false,
    on_insert = function(entry)
      local extension = entry:match "^.+(%..+)$"
      if not extension then
        extension = "no_extension"
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
