--- operations
-- @module operations
-- Table with simple operations that are not compatible between versions 5.1 and 5.3
-- this is done by `require ('motor.operations.' .. _VERSION:gsub('([%s%.])', ''):lower() .. '_operations')`
-- @usage
-- local operations = require "motor".operations
local localpath = (...):match("(.-)[^%.]+$")
local operations = require (localpath .. "operations." .. _VERSION:gsub('([%s%.])', ''):lower() .. '_operations')
return operations

--- the << operation.
-- @function lshift
-- @tparam number left
-- @tparam number right
-- @treturn number result
-- @usage
-- local operations = require 'motor.operations'
-- local lshift = operations.lshift
-- local a = 1 -- 0b0001
-- print(lshift(a. 1)) -- prints "2" (0b0010)
-- print(lshift(a. 2)) -- prints "4" (0b0100)
-- print(lshift(a. 3)) -- prints "8" (0b1000)


--- the & operation.
-- @function band
-- @tparam number left
-- @tparam number right
-- @treturn number result
-- @usage
-- local operations = require 'motor.operations'
-- local band = operations.band
-- local a = 1 -- 0b01
-- local b = 3 -- 0b11
-- print(band(a. b)) -- prints "1" (0b01)

--- the | operation.
-- @function bor
-- @tparam number left
-- @tparam number right
-- @treturn number result
-- @usage
-- local operations = require 'motor.operations'
-- local bor = operations.bor
-- local a = 1 -- 0b01
-- local b = 3 -- 0b11
-- print(bor(a. b)) -- prints "3" (0b11)

--- the ~ (binary) operation.
-- @function bxor
-- @tparam number left
-- @tparam number right
-- @treturn number result
-- @usage
-- local operations = require 'motor.operations'
-- local bxor = operations.bxor
-- local a = 1 -- 0b01
-- local b = 3 -- 0b11
-- print(bxor(a. b)) -- prints "2" (0b10)

--- combines two arrays in one.
-- @function combine_2_array_tables
-- @tparam table t1 first array
-- @tparam table t2 second array
-- @treturn table t1 and t2 merged
-- @usage
-- local operations = require 'motor.operations'
-- local a = {0, 1, 2}
-- local b = {3, 4, 5}
-- local r = operations.combine_2_array_tables(a, b) -- {0, 1, 2, 3, 4, 5}
