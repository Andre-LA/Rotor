--- bit_ids
-- @module bit_ids
local M = {}

local operations = require 'motor.operations'

local lshift = operations.lshift
local band   = operations.band
local bor    = operations.bor
local bxor    = operations.bxor

--- bit id array table.
--
-- A bit id is an array of numbers 0, with the exception of a single entry
-- that can be 2^x (that is, with value 1 in one of its bits), that array
-- is manipulated through bitwise operators and by default of size 4
-- (this limit is easily extended by editing the source code in `initial_bit_id` function)
--
-- bit id is used to identify "something", through @{bit_filter}s it is possible
-- to quickly operate the presence of multiple bit ids
--
-- For example, an entity associated with components identified as 0b001
-- and 0b100 will have a @{bit_filter} 0b101, so it is possible to identify
-- that the entity contains both the components identified as 0b001 and 0b100
--
-- When a new bit id is generated, it may have a predecessor, if so, the new
-- bit id is a copy of the predecessor, however the entry whose number
-- is different from 0 undergoes a bitwise shift to the left, otherwise a
-- new one is generated whose first entry is 1
--
-- When this bitwise left shift results in 0, the next entry will be used if possible
-- ({0, 1, 0, 0}), otherwise an error is triggered
-- @table bit_id
-- @tfield integer 1 = 1 initially
-- @tfield integer 2 = 0 initially
-- @tfield integer 3 = 0 initially
-- @tfield integer 4 = 0 initially

--- bit filter array table.
--
-- Same structure as @{bit_id}, but with only zeroes by default,  
-- is used to identify the presence of multiple @{bit_id}s
-- @table bit_filter
-- @tfield integer 1 = 0 initially
-- @tfield integer 2 = 0 initially
-- @tfield integer 3 = 0 initially
-- @tfield integer 4 = 0 initially


-- NOTE: if you want more entries in bit ids, adapt this function, for example:
-- local function initial_bit_id()
--   return {1, 0, 0, 0, 0, 0, 0, 0}
-- end
local function initial_bit_id()
  return {1, 0, 0, 0}
end

local function initial_bit_filter()
  local bit_filter = initial_bit_id()
  bit_filter[1] = 0
  return bit_filter
end

local BIT_ID_LEN = #initial_bit_id()

local function copy_bit_id(bit_id)
  local new_bit_id = initial_bit_id()

  -- maybe we can use table.move here?
  for i = 1, BIT_ID_LEN do
    new_bit_id[i] = bit_id[i]
  end

  return new_bit_id
end

--- Creates a new bit id.
-- @tparam[opt] bit_id previous_bit_id previous @{bit_id} to lshift
-- @usage
-- local bit_ids = require "motor.bit_ids"
-- 
-- local first_bit_id  = bit_ids.new_bit_id()              -- {1, 0, 0, 0}, 1 in binary is 001
-- local second_bit_id = bit_ids.new_bit_id(first_bit_id)  -- {2, 0, 0, 0}, 2 in binary is 010
-- local third_bit_id  = bit_ids.new_bit_id(second_bit_id) -- {4, 0, 0, 0}, 4 in binary is 100
-- @see bit_id
function M.new_bit_id(previous_bit_id)
  if not previous_bit_id then
    return initial_bit_id()
  end

  local new_bit_id = copy_bit_id(previous_bit_id)

  for i=1, BIT_ID_LEN do
    if new_bit_id[i] < 0 and new_bit_id[i+1] == 0 then
      new_bit_id[i] = 0
      new_bit_id[i+1] = 1
    end
  end

  assert(new_bit_id[BIT_ID_LEN] >= 0, "limit reached")

  for i=1, BIT_ID_LEN do
    new_bit_id[i] = lshift(new_bit_id[i], 1)
  end

  return new_bit_id
end

--- Creates a new bit filter.
-- @tparam[opt] {bit_id} bit_ids array of @{bit_id}s,
-- creates a new @{bit_filter} from multiples @{bit_id}s or a empty @{bit_filter}
-- @treturn bit_filter a new @{bit_filter}
-- @usage
-- local bit_ids = require "motor.bit_ids"
-- 
-- local first_bit_id  = bit_ids.new_bit_id()             -- {1, 0, 0, 0}, 1 in binary is 001
-- local second_bit_id = bit_ids.new_bit_id(first_bit_id) -- {2, 0, 0, 0}, 2 in binary is 010
-- 
-- local bit_filter = bit_ids.new_bit_filter({first_bit_id, second_bit_id}) -- {3, 0, 0, 0}, 3 in binary is 011
-- @see bit_id
-- @see bit_filter
function M.new_bit_filter(bit_ids)
  local bit_filter = initial_bit_filter()

  if bit_ids then
    for i=1, #bit_ids do
      local bit_ids_i = bit_ids[i]

      for j=1, BIT_ID_LEN do
        bit_filter[j] = bor(bit_filter[j], bit_ids_i[j])
      end
    end
  end

  return bit_filter
end

--- Add a new bit (from @{bit_id}) in the bit filter (set to 1)
-- @tparam bit_filter bit_filter bit filter to add the bit
-- @tparam bit_id bit_id bit to add
-- @usage
-- local bit_ids = require "motor.bit_ids"
-- 
-- local first_bit_id  = bit_ids.new_bit_id()             -- {1, 0, 0, 0}, 1 in binary is 001
-- local second_bit_id = bit_ids.new_bit_id(first_bit_id) -- {2, 0, 0, 0}, 2 in binary is 010
-- 
-- local bit_filter = bit_ids.new_bit_filter({first_bit_id, second_bit_id}) -- {3, 0, 0, 0}, 3 in binary is 011
-- 
-- local third_bit_id = bit_ids.new_bit_id(second_bit_id) -- {4, 0, 0, 0}, 4 in binary is 100
-- 
-- bit_ids.add_in_bit_filter(bit_filter, third_bit_id) -- bit_filter now is {7, 0, 0, 0}, 7 in binary is 111
-- @see bit_id
-- @see remove_in_bit_filter
-- @see bit_filter
function M.add_in_bit_filter(bit_filter, bit_id)
  for i=1, BIT_ID_LEN do
    bit_filter[i] = bor(bit_filter[i], bit_id[i])
  end
end

--- Remove a bit (from @{bit_id}) in the bit filter (set to 0)
-- @tparam bit_filter bit_filter bit filter to remove the bit
-- @tparam bit_id bit_id bit to remove
-- @usage
-- 
-- local bit_ids = require "motor.bit_ids"
-- 
-- -- (...) same algorithm in the add_in_bit_filter example
-- 
-- bit_ids.remove_in_bit_filter(bit_filter, second_bit_filter) -- bit filter now is {5, 0, 0, 0}, 5 in binary is 101
-- @see bit_id
-- @see add_in_bit_filter
-- @see bit_filter
function M.remove_in_bit_filter(bit_filter, bit_id)
  for i=1, BIT_ID_LEN do
    bit_filter[i] = bxor(bit_filter[i], bit_id[i])
  end
end

--- Checks if the left bit filter contains the bit ids in the 2nd bit filter
-- @tparam bit_filter bit_filter_l
-- @tparam bit_filter bit_filter_r
-- @usage
-- local bit_ids = require "motor.bit_ids"
-- 
-- local first_bit_id  = bit_ids.new_bit_id()              -- {1, 0, 0, 0}, 1 in binary is 001
-- local second_bit_id = bit_ids.new_bit_id(first_bit_id)  -- {2, 0, 0, 0}, 2 in binary is 010
-- local third_bit_id  = bit_ids.new_bit_id(second_bit_id) -- {4, 0, 0, 0}, 4 in binary is 100
-- 
-- local first_bit_filter  = bit_ids.new_bit_filter({first_bit_id, second_bit_id})               -- {3, 0, 0, 0}, 3 in binary is 011
-- local second_bit_filter = bit_ids.new_bit_filter({first_bit_id, second_bit_id, third_bit_id}) -- {7, 0, 0, 0}, 7 in binary is 111
-- 
-- print(bit_ids.contains_bit_ids(first_bit_filter, second_bit_filter)) -- prints "false"
-- print(bit_ids.contains_bit_ids(second_bit_filter, first_bit_filter)) -- prints "true"
-- @treturn boolean
-- @see bit_filter
function M.contains_bit_ids(bit_filter_l, bit_filter_r)
  for i=1, BIT_ID_LEN do
    local bit_filter_r_i = bit_filter_r[i] -- optimization
    if band(bit_filter_l[i], bit_filter_r_i) ~= bit_filter_r_i then
      return false
    end
  end

  return true
end

--- Is both bit ids equals?
-- @tparam bit_id bit_id_l
-- @tparam bit_id bit_id_r
-- @usage
-- local bit_ids = require "motor.bit_ids"
-- 
-- local first_bit_id  = bit_ids.new_bit_id()              -- {1, 0, 0, 0}, 1 in binary is 001
-- local second_bit_id = bit_ids.new_bit_id()              -- {1, 0, 0, 0}, 1 in binary is 001
-- local third_bit_id  = bit_ids.new_bit_id(second_bit_id) -- {2, 0, 0, 0}, 2 in binary is 010
-- 
-- print(bit_ids.equals(first_bit_id, second_bit_id)) -- prints "true"
-- print(bit_ids.equals(first_bit_id, third_bit_id))  -- prints "false"
-- @treturn boolean
-- @see bit_id
function M.equals(bit_id_l, bit_id_r)
  for i=1, BIT_ID_LEN do
    if bit_id_l[i] ~= bit_id_r[i] then
      return false
    end
  end

  return true
end

return M
