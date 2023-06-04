local Path = require "plenary.path"
local enum = require "telescope._extensions.tasks.enum"

local storage = {
  file = Path:new(vim.fn.stdpath "data", "telescope_tasks.json"),
}

local data = {}
local load_data
local loaded = false

local get_data
local check_keywords
local clean_data
local persist_data

---@class TaskStoredData
---@field cmd string
---@field env table
---@field cwd string?

---@return TaskStoredData?
function storage.get(task_keywords)
  if not check_keywords(task_keywords) then
    return nil
  end
  load_data()
  return get_data(task_keywords)
end

---@param task_keywords string[]
---@param task_data TaskStoredData?
---@return boolean
function storage.save(task_keywords, task_data)
  if not check_keywords(task_keywords) then
    return false
  end
  if type(data) ~= "table" then
    data = {}
  end
  local d = data
  for i, v in ipairs(task_keywords) do
    if type(v) ~= "string" then
      return false
    end
    if d[v] == nil then
      d[v] = {}
    end
    if i == #task_keywords then
      if type(d[v]) ~= "table" then
        d[v] = {}
      end
      d[v] = vim.tbl_deep_extend("force", d[v], task_data or {})
    else
      d = d[v]
    end
  end
  clean_data()
  return persist_data()
end

---@param task_keywords string[]
---@return boolean
function storage.delete(task_keywords)
  if not get_data(task_keywords) then
    return false
  end
  if type(data) ~= "table" then
    return false
  end
  local d = data
  for i, v in ipairs(task_keywords) do
    if type(v) ~= "string" then
      return false
    end
    if d[v] == nil then
      d[v] = {}
    end
    if i == #task_keywords then
      d[v] = nil
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
  if d == enum.NIL then
    return false
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

---@param task_keywords string[]?
---@return boolean
function check_keywords(task_keywords)
  return type(task_keywords) == "table" and next(task_keywords) ~= nil
end

---@param task_keywords string[]?
---@return table?
function get_data(task_keywords)
  if not check_keywords(task_keywords) or type(data) ~= "table" then
    return nil
  end
  local d = data
  for _, v in pairs(task_keywords or {}) do
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
