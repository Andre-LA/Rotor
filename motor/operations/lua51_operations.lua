--- Lua51_Operations
-- @module Lua51_Operations
-- operations using 5.1 features, but needs the 'bit' library,
-- bit is enabled by default in <a href="luajit.org">LuaJIT</a>
-- , but can also be installed with <a href="https://luarocks.org/modules/luarocks/luabitop">luarocks</a>

local _bit = bit or require 'bit'

return {
  -- bit operations
  lshift = _bit.lshift,
  band   = _bit.band,
  bor    = _bit.bor,
  bxor   = _bit.bxor,

  -- functions
  combine_2_array_tables = function(t1, t2)
    local new_table = {}

    for i=1, #t1 do
      new_table[i] = t1[i]
    end

    local new_table_len = #new_table
    for i=1, #t2 do
      new_table[new_table_len+i] = t2[i]
    end

    return new_table
  end,
}
