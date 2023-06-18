local scan = require("plenary.scandir")
local Path = require("plenary.path")

---@class State
---@field iterated_subdirectories string?
---@field found_files table
local State = {
  iterated_subdirectories = nil,
  parents_checked = 0,
  found_files = {},
}
State.__index = State

---@return State
function State:new()
  return setmetatable({}, State)
end

---@class FoundFiles
---@field by_extension table<string, table>
---@field by_name table<string, table>

---@param check_parents_nr number?
---@return FoundFiles
function State:find_files(check_parents_nr)
  if type(check_parents_nr) ~= "number" then
    check_parents_nr = 0
  end
  check_parents_nr = math.min(check_parents_nr, 10)

  local cwd = vim.fn.getcwd()
  if
    self.iterated_subdirectories == cwd
    and self.parents_checked == check_parents_nr
  then
    return self.found_files
  end
  if self.iterated_subdirectories ~= cwd then
    self:__iterate_subdirectories()
  end
  if self.parents_checked < check_parents_nr then
    self:__iterate_parents(check_parents_nr)
  end
  return self.found_files
end

local search_for_files = {
  extensions = {},
  names = {},
}
function State.register_file_extensions(extensions)
  for _, ext in ipairs(extensions) do
    search_for_files.extensions[ext] = true
  end
end

function State.register_file_names(names)
  for _, name in ipairs(names) do
    search_for_files.names[name] = true
  end
end

local on_insert

function State:__iterate_subdirectories()
  local cwd = vim.fn.getcwd()
  local cur_name = vim.api.nvim_buf_get_name(0)

  -- NOTE: identify the latest scan with
  -- the working directory, so we don't iterate
  -- multiple times, but just return the cached
  -- results (when multiple task generators require the file scan)
  self.iterated_subdirectories = cwd
  self.found_files = {}

  if
    not next(search_for_files.extensions) and not next(search_for_files.names)
  then
    return
  end
  -- NOTE: add current file to the list
  -- regardless of whether it exists in one
  -- of the cwd's subdirectories or not
  on_insert(self.found_files, cur_name)

  local max_depth = 7
  if cwd == os.getenv("HOME") then
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
          return on_insert(self.found_files, entry)
        end
        -- NOTE: scan only to a certain depth,
        -- tasks found in deeper directories
        -- are usually not relevant
        if o.depth >= max_depth then
          return
        end
        for _, pattern in ipairs(State.ignore_directories) do
          local tail = vim.fn.fnamemodify(entry, ":t")
          if tail == pattern then
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

function State:__iterate_parents(n)
  if n <= self.parents_checked then
    return
  end
  if type(self.found_files) ~= "table" then
    self.found_files = {}
  end
  local cur_name = vim.api.nvim_buf_get_name(0)

  ---@type Path
  local cur = Path:new(vim.fn.getcwd())
  for i = 1, n do
    cur = cur:parent()
    if i > self.parents_checked then
      scan.scan_dir(cur:__tostring(), {
        hidden = false,
        add_dirs = false,
        depth = 1,
        on_insert = function(entry)
          if not Path:new(entry):is_file() or entry == cur_name then
            return
          end
          return on_insert(self.found_files, entry)
        end,
      })
    end
  end
  self.parents_checked = n
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
  ".settings",
}

--- This will be called every time a file
--- is found during a file scan process.
on_insert = function(found_files, entry)
  if vim.fn.filereadable(entry) ~= 1 then
    return
  end
  local extension = vim.fn.fnamemodify(entry, ":e")
  local tail = vim.fn.fnamemodify(entry, ":t")
  if
    not search_for_files.extensions[extension]
    and not search_for_files.names[tail]
  then
    return
  end
  -- NOTE: store files both by their extensions
  -- and by their filename, as some generators
  -- might require to filter by extension (ex. *.go)
  -- and some by filename (ex. Makefile)
  if extension and extension:len() > 0 then
    if not found_files.by_extension then
      found_files.by_extension = {}
    end
    if not found_files.by_extension[extension] then
      found_files.by_extension[extension] = {}
    end
    table.insert(found_files.by_extension[extension], entry)
  end
  if tail and tail:len() > 0 then
    if not found_files.by_name then
      found_files.by_name = {}
    end
    if not found_files.by_name[tail] then
      found_files.by_name[tail] = {}
    end
    table.insert(found_files.by_name[tail], entry)
  end
end

return State
