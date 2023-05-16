local scan = require "plenary.scandir"
local Path = require "plenary.path"

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
  local cur_name = vim.api.nvim_buf_get_name(0)

  self.iterated_subdirectories = cwd
  self.found_files = {}

  local on_insert = function(entry)
    if vim.fn.filereadable(entry) ~= 1 then
      return
    end
    local extension = vim.fn.fnamemodify(entry, ":e")
    local tail = vim.fn.fnamemodify(entry, ":t")
    if extension and extension:len() > 0 then
      if not self.found_files.by_extension then
        self.found_files.by_extension = {}
      end
      if not self.found_files.by_extension[extension] then
        self.found_files.by_extension[extension] = {}
      end
      table.insert(self.found_files.by_extension[extension], entry)
    end
    if tail and tail:len() > 0 then
      if not self.found_files.by_name then
        self.found_files.by_name = {}
      end
      if not self.found_files.by_name[tail] then
        self.found_files.by_name[tail] = {}
      end
      table.insert(self.found_files.by_name[tail], entry)
    end
  end
  on_insert(cur_name)

  local max_depth = 7
  if cwd == vim.loop.os_homedir() then
    max_depth = 4
  end
  local stack = { { dir = cwd, depth = 1 } }

  while #stack > 0 do
    local o = table.remove(stack)
    scan.scan_dir(o.dir, {
      hidden = false,
      add_dirs = true,
      depth = 1,
      on_insert = function(entry)
        if Path:new(entry):is_file() then
          return on_insert(entry)
        end
        if o.depth >= max_depth then
          return
        end
        for _, pattern in ipairs(State.ignore_directories) do
          local tail = vim.fn.fnamemodify(entry, ":t")
          if tail:match(pattern) then
            return
          end
        end
        table.insert(stack, { dir = entry, depth = o.depth + 1 })
      end,
    })
  end
end

State.ignore_directories = {
  "node_modules",
  "vendor",
  "target",
  "dist",
  "build",
  "out",
  "bin",
  "obj",
  "lib",
  "deps",
  "venv",
  "env",
  "var",
  "Videos",
  "Pictures",
  "Games",
  "Movies",
  "snap",
  "usr",
  "tmp",
}

return State
