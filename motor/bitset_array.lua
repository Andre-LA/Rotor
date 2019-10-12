--- bitset array library
-- @module bitset_array

local operations = require "motor.lua5x-operations"

-- from Lua Manual: lua.org/manual/5.3/manual.html#3.4.2
-- Lua supports the following bitwise operators:

local op_band   = operations.band   -- &  bitwise AND
local op_bor    = operations.bor    -- |  bitwise OR
local op_bxor   = operations.bxor   -- ~  bitwise XOR
local op_rshift = operations.rshift -- >> right shift
local op_lshift = operations.lshift -- << left shift
local op_bnot   = operations.bnot   -- ~  bitwise NOT

local LEFTMOSTBIT = op_bnot(op_rshift(op_bnot(0), 1))


local new; -- future constructor

-- library functions

--- copies a bitset_array in a new one.
-- @function copy
-- @tparam bitset_array bitset_array bitset_array to copy
-- @treturn bitset_array
local function copy(bitset_array)
  local new_bitset_array = new()

  for i = 1, #bitset_array do
    new_bitset_array[i] = bitset_array[i]
  end

  return new_bitset_array
end
-- : read bitset_array -> new bitset_array

--- return if bitset_array values are equal
-- @function equals
-- @tparam bitset_array bitset_l bitset_array to compare
-- @tparam bitset_array bitset_r bitset_array to compare
-- @treturn boolean
local function equals(bitset_l, bitset_r)
  local len_l, len_r = #bitset_l, #bitset_r
  local len = len_l > len_r and len_l or len_r

  for i=1, len do
    if bitset_l[i] ~= bitset_r[i] then
      return false
    end
  end

  return true
end
-- : (read bitset_array, read bitset_array) -> boolean

-- basic binary bitwise operations

local function do_bin_bitop(bitset_l, bitset_r, default_vl, bitop_func)
  local len_l, len_r = #bitset_l, #bitset_r
  local len = len_l > len_r and len_l or len_r
  local result = new(len)

  for i=1, len do
    result[i] = bitop_func(bitset_l[i] or default_vl, bitset_r[i] or default_vl)
  end

  return result
end


--- creates a new bitset_array with the result
-- of the & bitwise operation between two bitset_arrays
-- @function band
-- @tparam bitset_array bitset_l
-- @tparam bitset_array bitset_r
-- @treturn bitset_array a new bitset_array with the result
local function band (bitset_l, bitset_r)
  return do_bin_bitop(bitset_l, bitset_r, 1, op_band)
end
-- : (read bitset_array, read bitset_array) -> new bitset_array

--- creates a new bitset_array with the result
-- of the | bitwise operation between two bitset_arrays
-- @function bor
-- @tparam bitset_array bitset_l
-- @tparam bitset_array bitset_r
-- @treturn bitset_array a new bitset_array with the result
local function bor (bitset_l, bitset_r)
  return do_bin_bitop(bitset_l, bitset_r, 0, op_bor)
end
-- : (read bitset_array, read bitset_array) -> new bitset_array

--- creates a new bitset_array with the result
-- of the (binary) ~ bitwise operation between two bitset_arrays
-- @function bxor
-- @tparam bitset_array bitset_l
-- @tparam bitset_array bitset_r
-- @treturn bitset_array a new bitset_array with the result
local function bxor (bitset_l, bitset_r)
  return do_bin_bitop(bitset_l, bitset_r, 0, op_bxor)
end
-- : (read bitset_array, read bitset_array) -> new bitset_array

-- basic unary bitwise operations

--- creates a new bitset_array with the result
-- of the (unary) ~ bitwise operation in a bitset_array
-- @function bxor
-- @tparam bitset_array bitset_array
-- @treturn bitset_array a new bitset_array with the result
local function bnot (bitset)
  local len = #bitset
  local result = new(len)

  for i = 1, #bitset do
    result[i] = op_bnot(bitset[i])
  end

  return result
end
-- : read bitset_array -> new bitset_array

--- creates a new bitset_array with the result
-- of the << bitwise operation between two bitset_arrays
-- if a bit overflows, it will go to the next index
-- @function lshift
-- @tparam bitset_array bitset_array to shift
-- @tparam integer steps steps to shift
-- @todo should grow if the last index bitset overflows
local function lshift (bitset, steps)
  local len = #bitset
  local result = copy(bitset)

  for _ = 1, steps do
    local previous_contained_leftmost_bit = false
    local result_prev_step = copy(result)

    for i = 1, len do
      local contains_leftmost_bit =
        op_band(result_prev_step[i], LEFTMOSTBIT) == LEFTMOSTBIT

      result[i] = op_lshift(result_prev_step[i], 1)

      if previous_contained_leftmost_bit then
        result[i] = op_bor(result[i], 1)
      end

      previous_contained_leftmost_bit = contains_leftmost_bit
    end
  end

  return result
end
-- : (read bitset_array, integer) -> new bitset_array

--- creates a new bitset_array with the result
-- of the >> bitwise operation between two bitset_arrays
-- if a bit overflows, it will go to the previous index
-- @function rshift
-- @tparam bitset_array bitset_array to shift
-- @tparam integer steps steps to shift
-- @todo should grow if the last index bitset overflows
local function rshift (bitset, steps)
  local len = #bitset
  local result = copy(bitset)

  for _ = 1, steps do
    local previous_contained_rightmost_bit = false
    local result_prev_step = copy(result)

    for i = len, 1, -1 do
      local contains_rightmost_bit = op_band(result_prev_step[i], 1) == 1

      result[i] = op_rshift(result_prev_step[i], 1)

      if previous_contained_rightmost_bit then
        result[i] = op_bor(result[i], LEFTMOSTBIT)
      end

      previous_contained_rightmost_bit = contains_rightmost_bit
    end
  end

  return result
end
-- : (read bitset_array, integer) -> new bitset_array

local methods = {
  equals = equals,
  copy   = copy,
  band   = band,
  bor    = bor,
  bxor   = bxor,
  lshift = lshift,
  rshift = rshift,
  bnot   = bnot,
}

local mt = {
  __index = methods
}

--- bitset_array is a table of integers
-- @table bitset_array

--- creates a new bitset_array table
-- @function new
-- @tparam integer initial_length initial length
-- @tparam {integer} initial_value initial values
-- @treturn bitset_array

-- new is a local variable declared in line 22
new = function(initial_length, initial_value)
  if not initial_value then
    initial_value = {}
  end

  local new_bitset_array = {initial_value[1] or 0}

  for i=2, (initial_length or 0) do
    new_bitset_array[i] = initial_value[i] or 0
  end

  setmetatable(new_bitset_array, mt)

  return new_bitset_array
end
-- : (integer, read {integer}) -> new bitset_array

return {
  new = new,  -- : (integer, read {integer}) -> new bitset_array

  equals = equals,
  -- : (read bitset_array, read bitset_array) -> boolean
  copy   = copy,
  -- : read bitset_array -> new bitset_array
  band   = band,
  -- : (read bitset_array, read bitset_array) -> new bitset_array
  bor    = bor,
  -- : (read bitset_array, read bitset_array) -> new bitset_array
  bxor   = bxor,
  -- : (read bitset_array, read bitset_array) -> new bitset_array
  lshift = lshift,
  -- : (read bitset_array, integer) -> new bitset_array
  rshift = rshift,
  -- : (read bitset_array, integer) -> new bitset_array
  bnot   = bnot
  -- : read bitset_array -> new bitset_array
}
