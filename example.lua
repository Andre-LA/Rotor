--require 'mobdebug'.on()

-- minimal example:-- 3 components: position, velocity and name
-- 2 systems: translator system and "who's on the right most?"
-- creates 3 entities, with these 2 components, but each one with different data
-- run these systems 300x
-- disassociate velocity component of all entities
-- print the position of the right most entity and it's name

-- requires
local states   = require 'motor.states'
local entities = require 'motor.entities'
local storages = require 'motor.storages'
local systems  = require 'motor.systems'

-- create the main_state
local main_state = states.new_state()

-- Declarations
-- =============

-- Declare components
-- ------------------

-- declare position, rotation and name component constructors
local function position_constructor(x, y)
  return {
    x = x,
    y = y
  }
end

local function velocity_constructor(v)
  return { v }
end

local function name_constructor(name)
  return { name }
end

-- create storages for each component type, and add them in the main_state
local positions_state_data_bit_id  = states.add_state_data(main_state, storages.new_storage())
local velocities_state_data_bit_id = states.add_state_data(main_state, storages.new_storage())
local names_state_data_bit_id      = states.add_state_data(main_state, storages.new_storage())

-- create a state data for the right most entity
local rightmost_components_bit_id = states.add_state_data(main_state, {})

-- Declare systems
-- ---------------

-- declare translator system
local translator_sys = systems.new_system(
  -- here you put state datas that won't be associated with entities,
  -- if no simple state data will be read or written, so you can use `false` instead of {{} ,{}}
  false
  ,{
    -- here you put state datas that will be associated with entities,
    -- in this case, read velocities and write positions
    {velocities_state_data_bit_id}, {positions_state_data_bit_id}
  },
  function(state_datas, simple_state_dt, components)
    print('translator system begin')
    for i = 1, #components do
      local vel_i = storages.get_entry_content(state_datas[velocities_state_data_bit_id], components[i][1])
      local pos_i = storages.get_entry_content(state_datas[positions_state_data_bit_id] , components[i][2])

      print("\tupdating position [".. i .. "]: " .. pos_i.x .. " with velocity " .. vel_i[1])
      pos_i.x = pos_i.x + vel_i[1]
    end
    print('translator system end')
  end
)



-- declare "who's on the right most" system
local who_in_right_sys = systems.new_system(
  {
    false, -- you can use false here too :)
    {rightmost_components_bit_id}
  }
  ,{
    {positions_state_data_bit_id, names_state_data_bit_id}, false -- and here too :3
  },
  function(state_datas, simple_state_data, components)
    print('"who\'s on the right most" system begin')

    local rightmost_pos = -999999999
    local rightmost_idx = 0

    for i = 1, #components do
      local pos_i  = storages.get_entry_content(state_datas[positions_state_data_bit_id], components[i][1])

      print("\tis pos[".. i .. "]: " .. pos_i.x .. " > " .. rightmost_pos .. " ?")
      if pos_i.x  > rightmost_pos then
        rightmost_pos = pos_i.x
        rightmost_idx = i
      end
    end

    state_datas[simple_state_data[1]].pos_id  = components[rightmost_idx][1]
    state_datas[simple_state_data[1]].name_id = components[rightmost_idx][2]
    
    local name_rm = storages.get_entry_content(state_datas[names_state_data_bit_id], components[rightmost_idx][2])
    print("\tThe rightmost for now is: " .. name_rm[1])
    print('"who\'s on the right most" system end')
  end
)


-- =================
-- Creating entities

for i=1, 3 do
  local entities_storage = main_state.state_data[main_state.entities_state_data_bit_id]


  -- create a new entity entry in entities storage
  local new_entity_id = storages.new_entry(
    entities_storage,
    entities.new_entity()
  )

  -- create a new name entry in names storage
  local new_name_id = storages.new_entry(
    main_state.state_data[names_state_data_bit_id],
    name_constructor("entity #" .. i)
  )

  -- create a new position entry in positions storage
  local new_position_id = storages.new_entry(
    main_state.state_data[positions_state_data_bit_id],
    position_constructor(math.random(-50, 50), 0)
  )

  -- create a new velocity entry in velocities storage
  local new_velocity_id = storages.new_entry(
    main_state.state_data[velocities_state_data_bit_id],
    velocity_constructor(math.random(0, 5))
  )

  -- associating these components in the new entity
  -- first, get the entry of the created entity
  local entry_of_new_entity = storages.get_entry_content(entities_storage, new_entity_id)

  -- associate it with new_name_id and names state data id
  entities.associate_component(
    entry_of_new_entity,
    new_name_id,
    names_state_data_bit_id
  )

  -- same
  entities.associate_component(
    entry_of_new_entity,
    new_position_id,
    positions_state_data_bit_id
  )

  -- same
  entities.associate_component(
    entry_of_new_entity,
    new_velocity_id,
    velocities_state_data_bit_id
  )
end

-- finally, we create a system step with these 2 systems!
states.new_systems_step(main_state, {translator_sys, who_in_right_sys})

-- setup systems, unfortunately this is still necessary before the first run
do
  -- get main_state's entities storage
  local entities_storage = main_state.state_data[main_state.entities_state_data_bit_id]

  -- for each step, for each system in this step, update components ids to iterate
  for step_i = 1, #main_state.systems do
    local step = main_state.systems[step_i]
  
    for system_i = 1, #step do
      systems.update_components_ids_to_iterate(step[system_i], entities_storage.entries)
    end
  end
end

-- in my computer (i5-4460S @ 2.90GHz × 4), motor can process, in this example, 
-- 1 million iterations per system per second in (PUC) Lua 5.3
-- and 10 million iterations per system per second in (LÖVE) LuaJIT,
-- in both it's just using only 1 thread!
print 'run main state start'

for i = 1, 300 do
  states.run(main_state)
end

print 'run main state end'

do -- disassociate velocity of all entities
  local entities_storage = main_state.state_data[main_state.entities_state_data_bit_id]

  for i=1, #entities_storage.entries do
    local entity = storages.get_entry_content(entities_storage, entities_storage.entries[i][1])
    
    -- disassociate
    entities.disassociate_component(
      entity, -- entity
      entity.associated_components_entries_ids[entities.find_associated_bit_id(entity, velocities_state_data_bit_id)], -- associated velocity id
      velocities_state_data_bit_id -- velocities state data bit id
    )
  end
end

-- print the rightmost entity's position and name
-- get registered ids

local position_id = main_state.state_data[rightmost_components_bit_id].pos_id
local name_id = main_state.state_data[rightmost_components_bit_id].name_id

-- get contents
local position = storages.get_entry_content(main_state.state_data[positions_state_data_bit_id], position_id)
local name = storages.get_entry_content(main_state.state_data[names_state_data_bit_id], name_id)

print('rightmost entity name "' .. name[1]  .. '" in the x position ' .. position.x)