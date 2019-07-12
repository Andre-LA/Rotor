--- generational index library
-- @module generational_index

--- return if two generational indexes are equals
-- @function equals
-- @tparam generational_index generational_index_l
-- @tparam generational_index generational_index_r
-- @treturn boolean
local function equals(generational_index_l, generational_index_r)
  return
    generational_index_l.index == generational_index_r.index
    and generational_index_l.generation == generational_index_r.generation
end
-- : (read generational_index, read generational_index) -> boolean

local id_methods = {
  equals = equals,
}

local id_mt = {
  __index = id_methods,
}

--- creates a new generational_index table
-- @function new
-- @tparam integer idx index field
-- @tparam integer gen generation field
-- @treturn generational_index
local function new(idx, gen)
  local new_generational_index = {
    index = idx,
    generation = gen
  } -- : generational_index

  setmetatable(new_generational_index, id_mt)
  return new_generational_index
end
-- : (integer, integer) -> new generational_index

--[[
  generational_index: {
    index: integer,
    generation: integer
  }
]]

-- for LDoc:

--- generational_index table
-- @tfield integer index
-- @tfield integer generation
-- @table generational_index

return {
  new = new, -- : (integer, integer) -> new generational_index
  equals = equals
  -- : (read generational_index, read generational_index) -> boolean
}
