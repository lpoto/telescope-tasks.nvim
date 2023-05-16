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

  -- NOTE: identify the latest scan with
  -- the working directory, so we don't iterate
  -- multiple times, but just return the cached
  -- results (when multiple task generators require the file scan)
  self.iterated_subdirectories = cwd
  self.found_files = {}

  --- This will be called every time a file
  --- is found during a file scan process.
  local on_insert = function(entry)
    if vim.fn.filereadable(entry) ~= 1 then
      return
    end
    local extension = vim.fn.fnamemodify(entry, ":e")
    local tail = vim.fn.fnamemodify(entry, ":t")
    -- NOTE: store files both by their extensions
    -- and by their filename, as some generators
    -- might require to filter by extension (ex. *.go)
    -- and some by filename (ex. Makefile)
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
  -- NOTE: add current file to the list
  -- regardless of whether it exists in one
  -- of the cwd's subdirectories or not
  on_insert(cur_name)

  local max_depth = 7
  if cwd == vim.loop.os_homedir() then
    max_depth = 4
  end

  -- NOTE: always scan only a single directory,
  -- and add subdirectories to the stack, so
  -- we can  filter out some directories during
  -- the scan process, instead of scanning the
  -- whole tree and then filtering out the results.
  local stack = { { dir = cwd, depth = 1 } }

  while #stack > 0 do
    -- pop a directory of the stack
    local o = table.remove(stack)

    scan.scan_dir(o.dir, {
      hidden = false,
      add_dirs = true,
      depth = 1,
      on_insert = function(entry)
        if Path:new(entry):is_file() then
          if entry == cur_name then
            -- NOTE: skip current file
            -- as it's already added above
            -- and we don't want to add it twice
            return
          end
          return on_insert(entry)
        end
        -- NOTE: scan only to a certain depth,
        -- tasks found in deeper directories
        -- are usually not relevant
        if o.depth >= max_depth then
          return
        end
        for _, pattern in ipairs(State.ignore_directories) do
          local tail = vim.fn.fnamemodify(entry, ":t")
          if tail:match(pattern) then
            return
          end
        end
        -- NOTE: the directory is not ignored,
        -- so we add it to the stack and scan it later
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
