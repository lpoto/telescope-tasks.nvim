local util = require "telescope._extensions.tasks.enum"
local executor = require "telescope._extensions.tasks.executor"
local State = require "telescope._extensions.tasks.model.state"

local should_run_generators

local runner = {}
local state = nil

--local generators_updated = false
local current_generators = {}
local last_tasks = {}

---Runs all the available generators.
---@return table: The found tasks
function runner.run(buf)
  -- NOTE: create a new runner state every time we run,
  -- so the generators may share data and generate tasks faster.
  state = State:new()

  local ok, tasks = pcall(function()
    if not next(current_generators or {}) then
      return {}
    end

    if type(buf) ~= "number" or not vim.api.nvim_buf_is_valid(buf) then
      buf = vim.api.nvim_get_current_buf()
    end

    local found_tasks = {}

    -- NOTE: should run only when current buftype is "" and
    -- the provided buf's buftype is ""
    if not should_run_generators(buf) then
      found_tasks = last_tasks
    else
      for _, generator in ipairs(current_generators or {}) do
        if generator:available() then
          found_tasks =
            vim.tbl_extend("force", found_tasks, generator:run() or {})
        end
      end
      last_tasks = found_tasks
    end

    found_tasks =
      vim.tbl_extend("force", found_tasks, executor.get_running_tasks() or {})

    return found_tasks
  end)

  state = nil

  if not ok and type(tasks) == "string" then
    util.error(tasks)
    return {}
  end
  return tasks or {}
end

function runner.add_generators(generators)
  for _, generator in ipairs(generators) do
    table.insert(current_generators, generator)
  end
end

---@return State|nil
function runner.get_state()
  return state
end

---Checks whether the generators should be run in the provided buffer.
---@param buf number
---@return boolean: Whether the generators should be run
should_run_generators = function(buf)
  local cur_buf = vim.api.nvim_get_current_buf()
  local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
  local cur_buftype = vim.api.nvim_buf_get_option(cur_buf, "buftype")
  return buftype:len() == 0 and cur_buftype:len() == 0
end

return runner
