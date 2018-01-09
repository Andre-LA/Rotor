local motor = {}
local Motor = {}
Motor.__index = Motor

local _floor = math.floor
local _table_remove = table.remove
local _setmetatable = setmetatable

-- this is how should look:
-- {position = components.position},
-- {velocity = components.velocity}},
-- {{"moveSystem", systems.moveSystem},
-- {"transformSystem", systems.transformSystem}}

local function bin_search(tbl, target)
   local min = 1
   local max = #tbl

   repeat
      local mid = _floor( (min + max)/2 )
      if tbl[mid] == target then
         return mid
      elseif target < tbl[mid] then
         max = mid - 1
      else
         min = mid + 1
      end
   until min > max
   return nil, "value " .. target .. " not found"
end

local function bin_search_with_key(tbl, target, key)
   local min = 1
   local max = #tbl

   repeat
      local mid = _floor( (min + max)/2 )
      if tbl[mid][key] == target then
         return mid
      elseif target < tbl[mid][key] then
         max = mid - 1
      else
         min = mid + 1
      end
   until min > max

   return nil, "value " .. target .. " of " .. key .. " key not found"
end

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

function Motor:get_world (world_id)
   return self.worlds[bin_search_with_key(self.worlds, world_id, 'id')]
end

function Motor:get_worlds (world_ids)
   local worlds = {}
      for wi=1,#world_ids do
         worlds[wi] = self:get_world(world_ids[wi])
      end
   return worlds
end

function Motor:new_world(systems_names)
   -- world structure:
   -- {
   --    id = (number)
   --    last_id = 0
   --    systems    = { system },
   --    entities   = { id, ... (components) },
   -- }

   self.last_world_id = self.last_world_id + 1
   self.worlds[#self.worlds+1] = {
      id       = self.last_world_id,
      last_id  = 0,
      systems  = {},
      entities = {},
   }

   local new_world = self.worlds[self.last_world_id]
   for sn=1,#systems_names do
      new_world.systems[sn] = self.systems[systems_names[sn]].new(self, self.last_world_id)
   end

   return self.last_world_id
end

local function update_systems_entities_on_add(world, entity)
   for s=1, #world.systems do
      local system = world.systems[s]
      if system.filter(entity) then
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

function Motor.get_entity (world, entity_id)
   return world.entities[bin_search_with_key(world.entities, entity_id, 'id')]
end

function Motor.get_entities (world, entities_ids)
   local entities = {}
      for ei=1,#entities_ids do -- ei: entity id
         entities[ei] = Motor.get_entity(world, entities_ids[ei], 'id')
      end
   return entities
end

function Motor.destroy_entity(world, entity_id)
   local entity_id_index = bin_search_with_key(world.entities, entity_id, 'id')
   _table_remove(world.entities, entity_id_index)
   update_systems_entities_on_remove(world, entity_id)
end

function Motor:set_components_on_entity (world, entity, component_names_and_values)
   for cnavi=1,#component_names_and_values, 2 do -- cnavi: Component Name And Value Index
      local component_name = component_names_and_values[cnavi]
      local component_constructor = self.components_constructors[component_name]
      local component_value = component_constructor(component_names_and_values[cnavi+1])
      entity[component_name] = component_value
   end
   update_systems_entities_on_add(world, entity)
end

-- TODO: update_systems_entities_on_destroy(world, entities)
function Motor.new_entities(world, quantity)
   local entities_ids = {}

   for ne=1, quantity do -- ne: new entity
      world.last_id = world.last_id + 1

      -- create the entity
      world.entities[#world.entities+1] = {id = world.last_id}

      -- register to the entities_ids, to return later
      entities_ids[ne] = world.last_id
   end

   return entities_ids
end


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

return motor
