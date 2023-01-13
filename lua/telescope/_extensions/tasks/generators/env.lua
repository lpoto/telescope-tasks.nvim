local ENV = {
  GO = {
    EXECUTABLE = "go",
    RUN = {
      -- go run [build flags] [-exec xprog] package [arguments...]
      XPROG = false,
      BUILD_FLAGS = {},
      ARGUMENTS = {},
    },
    MOD_FILE = "go.mod",
    ENV = {
      -- GOOS = "linux"
      -- ...
    },
  },
  CARGO = {
    EXECUTABLE = "cargo",
    RUN = {
      -- cargo run [options] [-- args]
      OPTIONS = {
        ["--message-format"] = "human",
      },
      ARGS = {},
    },
    CARGO_TOML = "Cargo.toml",
    ENV = {},
  },
  PYTHON = {
    EXECUTABLE = "python",
    OPTIONS = {},
    ARGUMENTS = {},
    ENV = {},
  },
}

local env = {}

function env.get(path, default)
  if type(path) == "string" then
    path = { path }
  end
  if type(path) ~= "table" or not next(path) then
    return default
  end
  local o = ENV
  for _, v in ipairs(path) do
    local ok, _ = pcall(function()
      o = o[v]
    end)
    if not ok then
      return default
    end
  end
  if o == nil then
    return default
  end
  return o
end

local recursively_add

function env.add(tbl)
  assert(type(tbl) == "table", "Env should be a table")
  for k, v in pairs(tbl) do
    ENV = recursively_add(ENV, k, v)
  end
end

recursively_add = function(to, key, value)
  if not to[key] then
    to[key] = value
    return to
  end

  assert(type(to[key]) == type(value), key .. " should be a " .. type(to[key]))

  if type(to[key]) ~= "table" then
    to[key] = value
    return to
  end

  for k, v in pairs(value) do
    to[key] = recursively_add(to[key], k, v)
  end

  return to
end

return env
