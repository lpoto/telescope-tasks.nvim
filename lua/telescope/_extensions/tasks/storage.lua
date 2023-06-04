local Path = require "plenary.path"

local storage = {
  file = Path:new(vim.fn.stdpath "data", "telescope_tasks.json"),
}

local data = {}
local load_data
local loaded = false

local get_data
local check_metadata
local clean_data
local persist_data

---@class TaskStoredData
---@field cmd string

---@return TaskStoredData?
function storage.get(task_metadata)
  if not check_metadata(task_metadata) then
    return nil
  end
  load_data()
  return get_data(task_metadata)
end

---@param task_metadata string[]
---@return boolean
function storage.delete(task_metadata)
  if not get_data(task_metadata) then
    return false
  end
  return storage.save(task_metadata, nil)
end

---@param task_metadata string[]
---@param task_data TaskStoredData?
---@return boolean
function storage.save(task_metadata, task_data)
  if not check_metadata(task_metadata) then
    return false
  end
  if type(data) ~= "table" then
    data = {}
  end
  local d = data
  for i, v in ipairs(task_metadata) do
    if type(v) ~= "string" then
      return false
    end
    if d[v] == nil then
      d[v] = {}
    end
    if i == #task_metadata then
      d[v] = task_data
    else
      d = d[v]
    end
  end
  clean_data()
  return persist_data()
end

function load_data()
  if loaded then
    return
  end
  loaded = true
  if not storage.file:is_file() then
    return
  end
  local ok, result = pcall(vim.fn.json_decode, storage.file:read())
  if not ok then
    return
  end
  if type(result) ~= "table" then
    return
  end
  data = result
end

function clean_data(d)
  if d == nil then
    d = data
  end
  if type(d) ~= "table" and d ~= nil then
    return true
  end
  if not next(d or {}) then
    return false
  end
  local ok = false
  for k, v in pairs(d) do
    if not clean_data(v) then
      d[k] = nil
    else
      ok = true
    end
  end
  return ok
end

---@param task_metadata string[]?
---@return boolean
function check_metadata(task_metadata)
  return type(task_metadata) == "table" and next(task_metadata) ~= nil
end

---@param task_metadata string[]?
---@return table?
function get_data(task_metadata)
  if not check_metadata(task_metadata) or type(data) ~= "table" then
    return nil
  end
  local d = data
  for _, v in pairs(task_metadata or {}) do
    if type(d) ~= "table" or type(v) ~= "string" then
      return nil
    end
    d = d[v]
  end
  return d
end

---@return boolean
function persist_data()
  if data == nil then
    return false
  end
  local ok, result = pcall(vim.fn.json_encode, data)
  if not ok then
    return false
  end
  if type(result) ~= "string" then
    return false
  end
  local err
  ok, err = pcall(storage.file.write, storage.file, result, "w")
  if not ok then
    return false
  end
  return true
end

return storage
