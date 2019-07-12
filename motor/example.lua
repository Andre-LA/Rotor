local entity = require 'motor.entity'
local storage = require 'motor.storage'
local system_data = require 'motor.system_data'
local bitset_array = require 'motor.bitset_array'

-- our components
local function create_position (x, y)
  return {x = x, y = y}
end

local function create_velocity (x, y)
  return {x = x, y = y}
end

-- is not a component, but will be processed by a system
local function create_rightmost()
  return {
    pos_comp = 0,
    name_comp = 0
  }
end

-- systems are just functions
local function movement_system(
  tr_system_data,
  velocities_storage,
  positions_storage
)
  for velocity, position in tr_system_data:iterate_components(
    {velocities_storage, positions_storage}, true
  ) do
    position.x = position.x + velocity.x
    position.y = position.y + velocity.y
  end
end

local function rightmost_system(
  rm_system_data,
  rightmost,
  names_storage,
  positions_storage
)
  local rightmost_position = -99999999

  for name, position in rm_system_data:iterate_components(
    {names_storage, positions_storage}, true
  ) do
    if position.x > rightmost_position then
      rightmost_position  = position.x
      rightmost.pos_comp  = position -- note: this is a reference
      rightmost.name_comp = name
    end
  end
end

local position_mask = bitset_array.new(1, {1})
local velocity_mask = bitset_array.new(1, {1}):lshift(1)
local name_mask     = bitset_array.new(1, {1}):lshift(2)

local movement_system_data = system_data.new(
  {velocity_mask}, {position_mask}
)

local rightmost_system_data = system_data.new(
  {name_mask, position_mask}
)

local positions_storage  = storage.new()
local velocities_storage = storage.new()
local names_storage      = storage.new()
local entities_storage   = storage.new()

local names_gen_indexes = {}

-- let's create 3 entities!
for i = 1, 3 do
  -- create an entity in the entities storage and get this new entity
  local new_entity_gen_idx = entities_storage:new_entry(entity.new())
  local new_entity = entities_storage:get_entry(new_entity_gen_idx)

  -- create the components in their respective storages.
  -- storage.new_entry(value) returns a generational_index, it's used as an ID
  local new_position = positions_storage:new_entry(
    create_position(math.random(-100.0, 100.0), i)
    -- create_position(x, y) returns just a new very simple table, remember?
  )

  local new_velocity = velocities_storage:new_entry(
    create_velocity(math.random(-200.0, 200.0), 0)
  )

  -- storages accepts any value
  names_gen_indexes[i] = names_storage:new_entry("entity #" .. i)

  -- this is how we associate an entity with a storage entry;
  -- making a unique bitmask per storage is necessary
  new_entity:associate(new_position, position_mask)
  new_entity:associate(new_velocity, velocity_mask)
  new_entity:associate(new_name, name_mask)
end

-- now, we update the systems datas, so they will know what entities
-- should be processed
movement_system_data:update_components_indexes(entities_storage)
rightmost_system_data:update_components_indexes(entities_storage)

-- let's execute movement system 10x
for _ = 1, 10 do
  movement_system(movement_system_data, velocities_storage, positions_storage)
end

local rightmost = create_rightmost()

-- let's execute rightmost_system, note that 'rigtmost' variable
-- is not an storage, component, or something specific;
-- since systems are just functions that you can declare and use
-- in whathever way you want, there is absolutely no special thing
-- in executing systems, they are just functions.
rightmost_system(
  rightmost_system_data, rightmost, names_storage, positions_storage
)

local n = 1
for e in entities_storage:iterate_entries() do

  -- note: methods are implemented using metatable and __index field,
  -- so, in all libraries used, methods are optional,
  -- you can use (and localize for performance) the function
  -- from the library

  entity.disassociate(e, position_mask)

  local disassociate = entity.disassociate
  disassociate(e, velocity_mask)

  -- you can also disassociate using the entry generational index
  e:disassociate(names_gen_indexes[n])
  n = n + 1
end

local name, pos_x = rightmost.name_comp, rightmost.pos_comp.x

print (
  'entity "'
  .. tostring(name)
  .. '" is in the rightmost position x: '
  .. tostring(pos_x)
)
