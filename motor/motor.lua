-- TODO: the documentation is TOTALLY deprecated,
-- I will update when Motor becomes stable
-- (this means: at least one complete game made in Motor)

--- motor: An ECS lua library.
-- check @{main.lua|main.lua example}
-- @see new
-- @license MIT
-- @author André Luiz Alvares
-- @module motor
local motor = {}

local _floor = math.floor
local _table_remove = table.remove
local _assert = assert

--- motor constructor
-- @function new
-- @tparam table components_constructors
-- @tparam table systems
-- @treturn table new motor instance
-- @usage
-- local universe = motor.new_universe(
--   { -- components constructors:
--     position = function(v) return {x = v.x, y = v.y} end,
--     velocity = function(v) return {x = v.x, y = v.y} end,
--     mesh     = function(v) return {value = love.graphics.newMesh(v.vertices, v.mode, v.usage)} end,
--     drawable = function(v, e) return {drawable = e[v.drawable].value} end,
--   },
--   { -- systems (will be executed in the following order):
--     require ("example_systems/move_system"),
--     require ("example_systems/draw_drawable_system"),
--   }
-- )
function motor.new_universe(components_constructors, systems)
  local new = {
    -- registered components_constructors and systems
    components_constructors = components_constructors,
    systems = {},
    worlds = {},
    last_world_id = 0,
  }

  for s=1, #systems do
    local system = systems[s]
    new.systems[s] = system
  end

  return new
end

--- @todo doc this!
function motor.new_system(_name, _filter)
  local new_system = {
    name = _name,
    filter = _filter,
  }

  new_system.__index = new_system

  new_system.new = function(_world)
    local system_constructor = {
      world = _world,
      entities = {},
    }
    setmetatable(system_constructor, new_system)
    return system_constructor
  end

  setmetatable(new_system, {
    __call = function(_, m, w)
      return new_system.new(m, w)
    end
  })

  return new_system
end


local function bin_search_with_key(tbl, target, key)
  local min = 1
  local max = #tbl

  while min <= max do
    local mid = _floor( (min + max)/2 )
    if tbl[mid][key] == target then
      return mid
    elseif target < tbl[mid][key] then
      max = mid - 1
    else
      min = mid + 1
    end
  end

  return nil, "value " .. target .. " of " .. key .. " key not found"
end

--- calls a function (if it exists) in all systems in all @{world|worlds}
-- @function call
-- @usage
-- function love.update(dt)
--    motor:call("update", dt)
-- end
-- @tparam string function_name the name of function to be called
-- @param ... parameters of the function to be called.
function motor.call(universe, function_name, ...)
  for w=1, #universe.worlds do
    local world = universe.worlds[w]
    for s=1, #world.systems do
      local system = world.systems[s]
      if system[function_name] then
        system[function_name](system, ...)
      end
    end
  end
end

--- World Functions
-- @section World

--- creates a new @{world} inside motor instance
-- @usage
-- local main_world_id, main_world_ref = motor:new_world({"move", "drawer"})
-- @see world
-- @function new_world
-- @tparam {string} systems_names each string is a system to be processed in the @{world}
-- @treturn number the id of the created @{world},
-- @treturn world the new world
function motor.new_world(universe, systems_names)
  universe.last_world_id = universe.last_world_id + 1

  universe.worlds[#universe.worlds+1] = {
    id       = universe.last_world_id,
    last_id  = 0,
    systems  = {},
    entities = {},
  }

  local new_world = universe.worlds[universe.last_world_id]

  for s=1, #universe.systems do
    for sn=1, #systems_names do
      if systems_names[sn] == universe.systems[s].name then
        new_world.systems[#new_world.systems+1] = universe.systems[s](new_world)
        break
      end
    end
  end

  return new_world
end

--- returns the @{world} of this id
-- @usage
-- local world_ref = motor:get_world(main_world_id)
-- @see world
-- @function get_world
-- @number world_id (integer) id of the @{world} to be obtained
-- @treturn world world reference
function motor.get_world (universe, world_id)
  return universe.worlds[bin_search_with_key(universe.worlds, world_id, 'id')]
end

local function update_systems_entities_on_add(world, entity)
  for s=1, #world.systems do
    local system = world.systems[s]
    if system.filter(entity) and not (bin_search_with_key(system.entities, entity.id, 'id')) then
      system.entities[#system.entities+1] = entity
    end
  end
end

local function update_systems_entities_on_remove(world, entity_id)
  for s=1, #world.systems do
    local system = world.systems[s]
    local entity_index_in_system = bin_search_with_key(system.entities, entity_id, 'id')
    if entity_index_in_system then
      _table_remove(system.entities, entity_index_in_system)
    end
  end
end

--- Entities Functions
-- @section Entity

local function create_entity(world, parent_id)
  -- incrementing last entity id of this world
  world.last_id = world.last_id + 1

  -- create the entity
  world.entities[#world.entities+1] = {
    id = world.last_id,
    parent_id = parent_id or 0,
    children = {},
  }

  return world.entities[#world.entities]
end

function motor.set_parent(world, entity, parent_id)
  -- if parent_id is nil, then entity will not have a parent

  if parent_id then
    -- register child to parent
    local parent_entity = motor.get_entity(world, parent_id)
    parent_entity.children[#parent_entity.children] = entity.id

  -- if the entity currently has a parent, unregister it
  elseif entity.parent_id ~= 0 then
    local parent_entity = motor.get_entity(world, entity.parent)

    for i=1, #parent_entity.children do
      if parent_entity.children[i] == entity.id then
        _table_remove(parent_entity.children, i)
      end
    end
  end

    -- register or unregister (respectively) child's parent
  entity.parent_id = parent_id or 0
end

--- Create an @{entity} in a @{world}
-- @function new_entity
-- @usage
-- local entity_id, entity_ref = motor.new_entity(world_ref)
-- @see entity
-- @see world
-- @tparam world world
-- @tparam[opt=0] number  parent_id optional parent id
-- @treturn number id of the new @{entity}
-- @treturn entity entity created
function motor.new_entity(world, parent_id)
  local new_entity = create_entity(world, parent_id)
  if parent_id then
    motor.set_parent(world, new_entity, parent_id)
  end
  return new_entity
end

--- get a @{entity}
-- @usage
-- local entity_ref = motor.get_entity(world_ref, entity_id)
-- @see world
-- @see entity
-- @function get_entity
-- @tparam world world table (not world id)
-- @tparam number entity_id id of the @{entity} to be obtained
-- @treturn entity entity reference of this id
function motor.get_entity (world, entity_id)
  return world.entities[bin_search_with_key(world.entities, entity_id, 'id')]
end

--- get a @{entity} with the given key [with the given value]
-- @usage
-- local entity_id, entity_ref = motor.get_entity_by_key(world_ref, "name", "André")
-- @see world
-- @see entity
-- @function get_entity_by_key
-- @tparam world world table
-- @tparam string key
-- @tparam[opt] value value
-- @treturn number entity id
-- @treturn entity entity
function motor.get_entity_by_key (world, key, value, subkeys)
  -- making value optional
  if not value then
    value = true
  end

  for i=1, #world.entities do
    local entity = world.entities[i]
    if entity[key] then
      local subkeys_count = subkeys and #subkeys or 0
      local key_value = entity[key]

      if subkeys_count > 0 then
        for k=1, subkeys_count do
          -- @todo TODO: introduce asserts in the next version
          key_value = key_value[subkeys[k]]
        end
      end

      if key_value == value then
        return entity
      end
    end
  end
end

--- set multiple components in an @{entity}
-- @usage
-- -- creating the world and getting a reference of it
-- main_world_id, world_ref = motor:new_world({"move", "drawer"})
--
-- -- creating one entity and getting a reference of it
-- entity_id, entity_ref = motor.new_entity(world_ref)
--
-- -- setting the entity components
-- motor:set_components(world_ref, entity_ref, {
--     "position", {x = 5, y = 5},
--     "velocity", {x = 1, y = 1},
--     "mesh"    , {vertices = {{-50, -50}, {50, -50}, {00, 50}}},
-- })
-- @function set_components
-- @tparam world world table (not world id)
-- @tparam entity entity to be modified
-- @tparam table component_names_and_values component names and values in pairs
function motor.set_components (universe, world, entity, component_names_and_values)
  for cnavi=1,#component_names_and_values, 2 do -- cnavi: Component Name And Value Index
    local component_name = component_names_and_values[cnavi]

    if component_name == "id" or component_name == "children" then
      print(
        "component pair ignored: '" .. component_name
        .. "' because " .. component_name .. " not should be modified here"
      )
    else
      local component_constructor = _assert(
        universe.components_constructors[component_name],
        "component constructor of '" .. component_name .. "' not found"
      )

      entity[component_name] = component_constructor(component_names_and_values[cnavi+1], world, entity, universe)
    end
  end

  update_systems_entities_on_add(world, entity)
end

--- destroy an @{entity}
-- @usage
-- motor.destroy_entity(world_ref, hero_id)
-- @function destroy_entity
-- @tparam world world table (not world id)
-- @tparam number entity_id id of the @{entity} to be destroyed
function motor.destroy_entity(world, entity_id)
  local entity_id_index = bin_search_with_key(world.entities, entity_id, 'id')
  _table_remove(world.entities, entity_id_index)
  update_systems_entities_on_remove(world, entity_id)
end

return motor

--- (Table) Structures
-- @section structures

--- World structure
-- @tfield number id id of this @{world}
-- @tfield number last_id used to generate entity ids, stores the id of the last entity
-- @tfield {system} the systems that will be processed in this @{world}. It is automatically generated by systems_names
-- @tfield {entity} entities
-- @table world

--- Entity structure:
-- an entity is just a table with id and components
-- @tfield number id id of the entity
-- @tfield number parent_id parent's id, if there is none, it will be 0.
-- @tfield table children children ids
-- @tfield table example_component_1
-- @tfield table example_component_2
-- @field ... other components
-- @table entity
