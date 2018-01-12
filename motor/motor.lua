--- Motor: An ECS-like lua library
-- @usage
-- -- see the main.lua file for a full example
-- local Motor = require ("motor/motor")
-- local motor = Motor.new(
--    { -- components constructors:
--        position = function(v) return {x = v.x, y = v.y} end,
--        velocity = function(v) return {x = v.x, y = v.y} end,
--        mesh     = function(v) return {mesh = love.graphics.newMesh(v.vertices, v.mode, v.usage)} end,
--        drawable = function(v) return {drawable = v.drawable} end,
--    },
--    { -- systems:
--       "move", require ("example_systems/move_system"),
--       "drawer", require ("example_systems/draw_drawable_system"),
--    }
-- )
-- @see new
-- @module Motor
local motor = {}
local Motor = {}
Motor.__index = Motor

local _floor = math.floor
local _table_remove = table.remove
local _setmetatable = setmetatable

--- Motor constructor
-- @function new
-- @tparam table components_constructors
-- @tparam table systems
-- @treturn table new Motor instance
-- @usage
-- local motor = Motor.new(
--    { -- components constructors:
--        position = function(v) return {x = v.x, y = v.y} end,
--        velocity = function(v) return {x = v.x, y = v.y} end,
--        mesh     = function(v) return {mesh = love.graphics.newMesh(v.vertices, v.mode, v.usage)} end,
--        drawable = function(v) return {drawable = v.drawable} end,
--    },
--    { -- systems:
--       "move", require ("example_systems/move_system"),
--       "drawer", require ("example_systems/draw_drawable_system"),
--    }
-- )
function motor.new(components_constructors, systems)
   local new = {
      -- registered components_constructors and systems
      components_constructors = components_constructors,
      systems = systems,
      worlds = {},
      last_world_id = 0,
   }

   _setmetatable(new, Motor)
   return new
end

local function bin_search(tbl, target)
   local min = 1
   local max = #tbl

   while min <= max do
      local mid = _floor( (min + max)/2 )
      if tbl[mid] == target then
         return mid
      elseif target < tbl[mid] then
         max = mid - 1
      else
         min = mid + 1
      end
   end
   return nil, "value " .. target .. " not found"
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
-- local main_world_id = motor:new_world({"move", "drawer"})
-- @see world
-- @function new_world
-- @tparam {string} systems_names each string is a system to be processed in the @{world}
-- @treturn number the id of the created @{world}
function Motor:new_world(systems_names)

   self.last_world_id = self.last_world_id + 1
   self.worlds[#self.worlds+1] = {
      id       = self.last_world_id,
      last_id  = 0,
      systems  = {},
      entities = {},
   }

   local new_world = self.worlds[self.last_world_id]

   for s=1, #self.systems, 2 do
      for sn=1, #systems_names do
         if systems_names[sn] == self.systems[s] then
            new_world.systems[#new_world.systems+1] = self.systems[s+1].new(self, self.last_world_id)
            break
         end
      end
   end

   return self.last_world_id
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

--- returns multiple @{world}s from multiple world ids
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
      if system.filter(entity) and not (bin_search(system.ids, entity.id)) then
         system.ids[#system.ids+1] = entity.id
      end
   end
end

local function update_systems_entities_on_remove(world, entity_id)
   for s=1, #world.systems do
      local system = world.systems[s]
      local entity_id_index_in_system = bin_search(system.ids, entity_id)
      if entity_id_index_in_system then
         _table_remove(system.ids, entity_id_index_in_system)
      end
   end
end

--- Entities Functions
-- @section Entity

--- Create an @{entity} in a @{world}
-- @function new_entity
-- @usage
-- local entity_id = motor.new_entity(world_ref)
-- @see entity
-- @see world
-- @tparam world world
-- @treturn number id of the new @{entity}
function Motor.new_entity(world)
   world.last_id = world.last_id + 1 -- incrementing last entity id of this world
   world.entities[#world.entities+1] = {id = world.last_id} -- create the entity
   return world.last_id -- return the id of created entity
end

--- create multiple entities in a @{world}
-- @usage
-- local some_entities_ids = motor.new_entities(world_ref, 4)
-- @tparam world world
-- @tparam number quantity quantity of @{entity|entities} to be created in this @{world}
-- @treturn {number} table of entities ids created
function Motor.new_entities(world, quantity)
   local entities_ids = {}
   for i=1, quantity do
      entities_ids[i] = Motor.new_entity(world)
   end
   return entities_ids
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
      entities[ei] = Motor.get_entity(world, entities_ids[ei], 'id')
   end
   return entities
end

--- set multiple components in an @{entity}
-- @usage
-- -- creating the world and getting a reference of it
-- main_world_id = motor:new_world({"move", "drawer"})
-- local world_ref = motor:get_world(main_world_id)
--
-- -- creating one entity and getting a reference of it
-- entity_id = motor.new_entity(world_ref)
-- local entity_ref = motor.get_entity(world_ref, entity_id)
--
-- -- setting the entity components
-- motor:set_components_on_entity(world_ref, entity_ref, {
--     "position", {x = 5, y = 5},
--     "velocity", {x = 1, y = 1},
--     "mesh"    , {vertices = {{-50, -50}, {50, -50}, {00, 50}}},
-- })
-- @function set_components_on_entity
-- @tparam world world table (not world id)
-- @tparam entity entity to be modified
-- @tparam table component_names_and_values component names and values in pairs
function Motor:set_components_on_entity (world, entity, component_names_and_values)
   for cnavi=1,#component_names_and_values, 2 do -- cnavi: Component Name And Value Index
      local component_name = component_names_and_values[cnavi]
      local component_constructor = self.components_constructors[component_name]
      entity[component_name] = component_constructor(component_names_and_values[cnavi+1])
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
-- @tfield table example_component_1
-- @tfield table example_component_2
-- @field ... other components
-- @table entity
