--- Motor: An ECS-like lua library.
-- check @{main.lua|main.lua example}
-- @see new
-- @license MIT
-- @author André Luiz Alvares
-- @module Motor
local motor = {}
local Motor = {}
Motor.__index = Motor

local _floor = math.floor
local _table_remove = table.remove

--- Motor constructor
-- @function new
-- @tparam table components_constructors
-- @tparam table systems
-- @treturn table new Motor instance
-- @usage
-- local motor = Motor.new(
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
function motor.new(components_constructors, systems)
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

  setmetatable(new, Motor)
  return new
end

setmetatable(motor, {__call = function(_, cc, s) return motor.new(cc, s) end})

--- @todo doc this!

function motor.new_system(_name, _filter)
  local new_system = {
    name = _name,
    filter = _filter,
  }

  new_system.__index = new_system

  new_system.new = function(motor_instance, _world)
    local system_constructor = {
      motor = motor_instance,
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
function Motor:call(function_name, ...)
  for w=1, #self.worlds do
    local world = self.worlds[w]
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
function Motor:new_world(systems_names)
  self.last_world_id = self.last_world_id + 1

  self.worlds[#self.worlds+1] = {
    id       = self.last_world_id,
    last_id  = 0,
    systems  = {},
    entities = {},
  }

  local new_world = self.worlds[self.last_world_id]

  for s=1, #self.systems do
    for sn=1, #systems_names do
      if systems_names[sn] == self.systems[s].name then
        new_world.systems[#new_world.systems+1] = self.systems[s](self, new_world)
        break
      end
    end
  end

  return self.last_world_id, new_world
end

--- returns the @{world} of this id
-- @usage
-- local world_ref = motor:get_world(main_world_id)
-- @see world
-- @function get_world
-- @number world_id (integer) id of the @{world} to be obtained
-- @treturn world world reference
function Motor:get_world (world_id)
  return self.worlds[bin_search_with_key(self.worlds, world_id, 'id')]
end

--- returns multiple @{world|worlds} from multiple world ids
-- @see world
-- @function get_worlds
-- @tparam {number} world_ids table of ids
-- @treturn {world} a table of worlds
function Motor:get_worlds (world_ids)
  local worlds = {}
  for wi=1,#world_ids do
    worlds[wi] = self:get_world(world_ids[wi])
  end
  return worlds
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
  world.last_id = world.last_id + 1 -- incrementing last entity id of this world
  -- create the entity
  world.entities[#world.entities+1] = {
    id = world.last_id,
    parent_id = parent_id or 0,
    children = {},
  }
  return world.last_id, world.entities[#world.entities] -- return the id of created entity and the entity
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
function Motor.new_entity(world, parent_id)
  local new_entity_id, new_entity = create_entity(world, parent_id)
  if parent_id then
    local parent_entity = Motor.get_entity(world, parent_id)
    parent_entity.children[#parent_entity.children+1] = new_entity_id
  end
  return new_entity_id, new_entity
end

--- create multiple @{entity|entities} in a @{world}
-- @usage
-- local some_entities_ids = motor.new_entities(world_ref, 4)
-- @tparam world world
-- @tparam number quantity quantity of @{entity|entities} to be created in this @{world}
-- @tparam[pot=0] number parent_id optional parent_id
-- @treturn {number} table of entities ids created
-- @treturn {entity} table of entities created
function Motor.new_entities(world, quantity, parent_id)
  local new_entities_ids, new_entities = {}, {}
  for i=1, quantity do
    new_entities_ids[i], new_entities[i] = create_entity(world, parent_id)
  end
  if parent_id then
    local parent_entity = Motor.get_entity(world, parent_id)
    local c = 1
    for i = #parent_entity.children + 1, #parent_entity.children + #new_entities_ids do
      parent_entity.children[i] = new_entities_ids[c]
      c = c + 1
    end
  end
  return new_entities_ids, new_entities
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
function Motor.get_entity (world, entity_id)
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
function Motor.get_entity_by_key (world, key, value)
  for i=1, #world.entities do
    local entity = world.entities[i]
    if entity[key] and (value ~= nil and entity[key] == value or true) then
      return entity.id, entity
    end
  end
end

-- @todo create get_entities_by_key

--- get multiple @{entity|entities}
-- @see world
-- @see entity
-- @usage
-- local some_entities = motor.get_entity(world_ref, entity_id)
-- @function get_entities
-- @tparam world world of this entities
-- @tparam {number} entities id
-- @treturn {entity} table of multiple @{entity|entities}
function Motor.get_entities (world, entities_ids)
  local entities = {}
  for ei=1,#entities_ids do -- ei: entity id
    entities[ei] = Motor.get_entity(world, entities_ids[ei])
  end
  return entities
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
function Motor:set_components (world, entity, component_names_and_values)
  for cnavi=1,#component_names_and_values, 2 do -- cnavi: Component Name And Value Index
    local component_name = component_names_and_values[cnavi]
    local component_constructor = self.components_constructors[component_name]
    entity[component_name] = component_constructor(component_names_and_values[cnavi+1], self, world)
  end
  update_systems_entities_on_add(world, entity)
end

--- destroy an @{entity}
-- @usage
-- motor.destroy_entity(world_ref, hero_id)
-- @function destroy_entity
-- @tparam world world table (not world id)
-- @tparam number entity_id id of the @{entity} to be destroyed
function Motor.destroy_entity(world, entity_id)
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
