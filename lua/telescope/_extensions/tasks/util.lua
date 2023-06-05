local enum = require "telescope._extensions.tasks.enum"
local Path = require "plenary.path"

local util = {}

local log_level = nil
local find_root
local notify

function util.warn(...)
  notify(vim.log.levels.WARN, ...)
end

function util.error(...)
  notify(vim.log.levels.ERROR, ...)
end

function util.info(...)
  notify(vim.log.levels.INFO, ...)
end

---Find a parent directory of the current working directory
---containing at least one file or directory
---present in the provided `files_and_directories` table.
---The parent directory may be the current working directory itself.
---When no such parent is found, the current working directory is returned.
---@return string
function util.find_parent_root(files_and_directories)
  local _, root = find_root(files_and_directories, vim.loop.cwd())
  return root
end

---Find a parent directory of the current file,
---containing at least one file or directory
---present in the provided `files_and_directories` table.
---When no such parent is found, the file's parent directory is returned.
---@return string
function util.find_current_file_root(files_and_directories)
  local _, root = find_root(files_and_directories, vim.fn.expand "%:p:h")
  return root
end

---Find a parent directory of the provided file,
---containing at least one file or directory
---present in the provided `files_and_directories` table.
---When no such parent is found, the file's parent directory is returned.
---@return string
function util.find_file_root(file, files_and_directories)
  local _, root = find_root(files_and_directories, file)
  return root
end

---Returns true if any of the current file's
---parent directories include any of the provided files or directories.
---@return boolean
function util.parent_dir_includes(files_and_directories)
  local ok, _ = find_root(files_and_directories, vim.fn.expand "%:p:h")
  return ok
end

---@param s string
---@return string
function util.trim_string(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---@param n string
function util.get_env(n)
  if
    type(vim.g.telescope_tasks) ~= "table"
    or type(vim.g.telescope_tasks.env) ~= "table"
    or type(vim.g.telescope_tasks.env[n]) ~= "table"
  then
    return nil
  end
  return vim.g.telescope_tasks_env[n]
end

find_root = function(patterns, start)
  local start_path = Path:new(start)
  local parents = start_path:parents()
  table.insert(parents, start)

  for _, parent in ipairs(parents) do
    for _, file_or_dir in ipairs(patterns) do
      if Path:new(parent):joinpath(file_or_dir):exists() then
        return true, parent
      end
    end
  end
  if start_path:is_file() then
    return false, start_path:parent():__tostring()
  end
  return false, start_path:__tostring()
end

function notify(lvl, ...)
  if log_level ~= nil and log_level > lvl then
    return
  end
  local args = { select(1, ...) }
  vim.schedule(function()
    local s = ""
    for _, v in ipairs(args) do
      if type(v) ~= "string" then
        v = vim.inspect(v)
      end
      if s:len() > 0 then
        s = s .. " " .. v
      else
        s = v
      end
    end
    if s:len() > 0 then
      vim.notify(s, lvl, {
        title = enum.TITLE,
      })
    end
  end)
end

function util.get_binary(n)
  if type(vim.g.telescope_tasks) ~= "table" then
    return nil
  end
  if type(vim.g.telescope_tasks.binaries) ~= "table" then
    return nil
  end
  if type(vim.g.telescope_tasks.binaries[n]) ~= "string" then
    return nil
  end
  return vim.g.telescope_tasks.binaries[n]
end

return util
