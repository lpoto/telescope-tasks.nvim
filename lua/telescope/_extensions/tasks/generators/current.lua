---@class Generator_opts
---@field filetypes table|nil
---@field patterns table|nil
---@field ignore_patterns table|nil
---@field name string|nil

local generators = {}

local verify_parameters
local verify_batch_generators
local call_generator_callback

local current_generators = {}

---@param generator function|table
---@return table: The added generator
function current_generators.add(generator)
  if type(generator) == "function" then
    generator = {
      generator = generator,
    }
  end
  verify_parameters(
    generator.generator or generator[1],
    generator.opts or generator[2]
  )

  local to_insert = {
    name = (generator.opts or {}).name or "Custom",
    generator = generator.generator,
    opts = generator.opts,
  }
  table.insert(generators, to_insert)
  return to_insert
end

---@param batch table
---@return table: A table of added generators
function current_generators.add_batch(batch)
  verify_batch_generators(batch)

  local inserted = {}
  for _, generator in ipairs(batch) do
    table.insert(inserted, current_generators.add(generator))
  end
  return inserted
end

---@return boolean: Whether there are no current generators
function current_generators.is_empty()
  return next(generators or {}) == nil
end

---iteratre over the currently available generators.
---Their availabily is determined based on the Generator_opts
---provided when adding the generators.
---@param callback function: Callback to execute for each generator
---@param to_iterate table|nil: A table of generators to iterate over, when
---nil, the current generators will be used.
function current_generators.iterate_available(callback, to_iterate)
  local buf = vim.fn.bufnr()
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  local filename = vim.api.nvim_buf_get_name(buf)

  for _, generator in ipairs(to_iterate or generators or {}) do
    local opts = generator.opts or {}

    call_generator_callback(
      filetype,
      filename,
      generator.generator,
      generator.name,
      opts or {},
      callback
    )
  end
end

---@param generator function
---@param opts Generator_opts?
verify_parameters = function(generator, opts)
  assert(type(generator) == "function", "Generator must be a function")
  assert(
    opts == nil or type(opts) == "table",
    "Generator options must be a table"
  )
  for k, v in pairs(opts or {}) do
    assert(type(k) == "string", "Generator options keys must be strings")
    assert(
      (
      ({ filetypes = true, patterns = true, ignore_patterns = true })[k]
          and type(v) == "table"
      ) or k == "name" and type(v) == "string",
      "Invalid generator option: " .. k
    )
  end
end

verify_batch_generators = function(batch)
  assert(type(batch) == "table", "A batch of generators must be a table")
end

call_generator_callback =
function(filetype, filename, generator, name, opts, cb)
  if opts.filetypes and not vim.tbl_contains(opts.filetypes, filetype) then
    return
  end
  if opts.patterns then
    local ok = false
    for _, pattern in ipairs(opts.patterns) do
      if filename:match(pattern) then
        ok = true
        break
      end
    end
    if not ok then
      return
    end
  end
  if opts.ignore_patterns then
    local ok = true
    for _, pattern in ipairs(opts.ignore_patterns) do
      if filename:match(pattern) then
        ok = false
        break
      end
    end
    if not ok then
      return
    end
  end
  cb(generator, name)
end

return current_generators
