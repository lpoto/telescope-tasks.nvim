local Path = require "plenary.path"

local path = {}

local find_root

---Find a parent directory of the current working directory
---containing at least one file or directory
---present in the provided `files_and_directories` table.
---The parent directory may be the current working directory itself.
---When no such parent is found, the current working directory is returned.
---@return string
function path.find_parent_root(files_and_directories)
  local _, root = find_root(files_and_directories, vim.loop.cwd())
  return root
end

---Find a parent directory of the current file,
---containing at least one file or directory
---present in the provided `files_and_directories` table.
---When no such parent is found, the file's parent directory is returned.
---@return string
function path.find_current_file_root(files_and_directories)
  local _, root = find_root(files_and_directories, vim.fn.expand "%:p:h")
  return root
end

---Returns true if any of the current file's
---parent directories include any of the provided files or directories.
---@return boolean
function path.parent_dir_includes(files_and_directories)
  local ok, _ = find_root(files_and_directories, vim.fn.expand "%:p:h")
  return ok
end

find_root = function(patterns, start)
  local parents = Path:new(start):parents()
  table.insert(parents, start)

  for _, parent in ipairs(parents) do
    for _, file_or_dir in ipairs(patterns) do
      if Path:new(parent):joinpath(file_or_dir):exists() then
        return true, parent
      end
    end
  end
  return false, start
end

return path
