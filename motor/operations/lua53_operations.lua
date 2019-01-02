--- Lua53_Operations
-- @module Lua53_Operations
-- operations using 5.3 features

local move = table.move

return {
  -- bit operations
  lshift = function(a, b) return a << b end,
  band   = function(a, b) return a & b end,
  bor    = function(a, b) return a | b end,
  bxor    = function(a, b) return a ~ b end,

  -- functions
  combine_2_array_tables = function(t1, t2)
    local new_table = {}
    move(t1, 1, #t1, 1, new_table)
    move(t2, 1, #t2, #new_table+1, new_table)
    return new_table
  end,
}
