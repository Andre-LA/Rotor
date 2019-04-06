--- systems
-- @module systems
local operations = require ("motor.operations")
local bit_ids    = require ("motor.bit_ids")
local storages   = require ("motor.storages")

local combine_arrays = operations.combine_2_array_tables

--- Updates the components ids to iterate when runs
-- , needed when an entity is deleted, but Motor handles that automatically, only necessary
-- to run outside before the first state's run
-- @tparam system System system to update components ids
-- @tparam {storages.Entry} entities_entries entities entries in the entities storage
-- @see example.lua
-- @usage
-- -- unfortunately this is still necessary before the first state's run
-- -- get main_state's entities storage
-- local entities_storage = main_state.state_content[main_state.entities_state_content_bit_id]
--
-- -- for each step, for each system in this step, update components ids to iterate
-- for step_i = 1, #main_state.systems do
--   local step = main_state.systems[step_i]
--
--   for system_i = 1, #step do
--     systems.update_components_ids_to_iterate(step[system_i], entities_storage.entries)
--   end
-- end
local function update_components_ids_to_iterate(system, entities_entries)
  local components_ids_to_system = {}

  -- for each entity entry
  for entities_i = 1, #entities_entries do
    local entity_entry = entities_entries[entities_i]

    -- if entry is valid and alive
    if entity_entry and entity_entry.is_alive then
      local entity = entity_entry.content

      -- does this entity contains the required components?
      if bit_ids.contains_bit_ids(entity.state_content_bit_filter, system.component_state_content_bit_filter) then
        -- then we will get the ids of the associated components
        local components_tuple = {}
        local components_tuple_n = 0

        -- for each state data bit_id needs of a system_data
        for system_needs_i = 1, #system.component_needs do

          -- for each associated state_content bit_id of an entity
          for entity_associated_state_content_bit_ids_i=1, #entity.associated_state_content_bit_ids do
            local associated_state_content_bit_id
              = entity.associated_state_content_bit_ids[entity_associated_state_content_bit_ids_i]

            -- is this associated_state_content_bit_id one of the components_ids that the system_data needs?
            if bit_ids.equals(associated_state_content_bit_id, system.component_needs[system_needs_i]) then
              -- insert associated component entry id in components_tuple
              -- index of associated components and associated state_content ids is the same :)
                components_tuple_n = components_tuple_n + 1
                components_tuple[components_tuple_n]
                  = entity.associated_components_entries_ids[entity_associated_state_content_bit_ids_i]

              break
            end

          end
        end

        if #components_tuple > 0 then
          components_ids_to_system[#components_ids_to_system+1] = components_tuple
        end
      end
    end
  end

  system.components_ids_to_iterate = components_ids_to_system
end

--- Delete dead entries if necessary, if it does,
-- update components ids of the system data
local function prepare(system_data, entities_storage)
  if storages.delete_dead_entries(entities_storage) then
    update_components_ids_to_iterate(system_data, entities_storage.entries)
  end
end

local SystemData_mt = {
  __index = {
    update_components_ids_to_iterate = update_components_ids_to_iterate,
    prepare = prepare
  }
}

--- SystemData record
-- @table SystemData
-- @tfield {bit_ids.bit_id} component_needs
-- @tfield {bit_ids.bit_id} simple_state_content_needs
-- @tfield bit_ids.bit_filter component_state_content_bit_filter
-- @tfield function run
-- @tfield {storages.id} components_ids_to_iterate
local SystemData = {
  new = function (component_needs, simple_state_content_needs, component_state_content_bit_filter, components_ids_to_iterate)
    local new_system_data = {
      component_needs = component_needs,
      simple_state_content_needs = simple_state_content_needs,
      component_state_content_bit_filter = component_state_content_bit_filter,
      components_ids_to_iterate = components_ids_to_iterate,
    }

    setmetatable(new_system_data, SystemData_mt)

    return new_system_data
  end
}

--- Create a new System
-- @tparam {bit_ids.bit_id} required_simple_state_content simple state datas to read and write
-- @tparam {bit_ids.bit_id} required_compnt_state_content component state datas to read and write
-- @treturn system
local function new_init_system_data(required_simple_state_content, required_compnt_state_content)
  local compnt_state_content_reads  = required_compnt_state_content[1]

  local compnt_state_content_writes = required_compnt_state_content[2]

  local compnt_state_content_needs  = combine_arrays(compnt_state_content_reads, compnt_state_content_writes)

  local simple_state_content_reads  = required_simple_state_content[1]

  local simple_state_content_writes = required_simple_state_content[2]

  local simple_state_content_needs  = combine_arrays(simple_state_content_reads, simple_state_content_writes)

  local new_system_data = SystemData.new(
    compnt_state_content_needs,
    simple_state_content_needs,
    bit_ids.new_bit_filter(compnt_state_content_needs),
    {}
  )

  return new_system_data
end

return {
  SystemData = SystemData,
  new_init_system_data = new_init_system_data,
  update_components_ids_to_iterate = update_components_ids_to_iterate
}
