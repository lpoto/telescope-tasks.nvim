local scan = require "plenary.scandir"

---@class Runner_state
---@field iterated_subdirectories boolean
---@field found_files table
local Runner_state = {
  iterated_subdirectories = false,
  found_files = {},
}
Runner_state.__index = Runner_state

---@return Runner_state
function Runner_state:new()
  return setmetatable({}, Runner_state)
end

---@return table
function Runner_state:find_files()
  if self.iterated_subdirectories then
    return self.found_files
  end
  self:__iterate_subdirectories()
  return self.found_files
end

function Runner_state:__iterate_subdirectories()
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

return Runner_state
