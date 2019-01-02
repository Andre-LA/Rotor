--- systems
-- @module systems
local M = {}

local operations = require 'motor.operations'
local bit_ids = require 'motor.bit_ids'

local combine_arrays = operations.combine_2_array_tables

local table_insert = table.insert -- optimization :3

--- system table
-- @table system
-- @tfield {bit_ids.bit_id} all_reads
-- @tfield {bit_ids.bit_id} all_writes
-- @tfield {bit_ids.bit_id} all_needs
-- @tfield {bit_ids.bit_id} component_reads
-- @tfield {bit_ids.bit_id} component_writes
-- @tfield {bit_ids.bit_id} component_needs
-- @tfield {bit_ids.bit_id} simple_state_data_reads
-- @tfield {bit_ids.bit_id} simple_state_data_writes
-- @tfield {bit_ids.bit_id} simple_state_data_needs
-- @tfield bit_ids.bit_filter all_bit_filter
-- @tfield bit_ids.bit_filter compnt_state_data_bit_filter
-- @tfield bit_ids.bit_filter simple_state_data_bit_filter
-- @tfield function run
-- @tfield {storages.id} components_ids_to_iterate


--- Create a new System
-- @param required_simple_state_data simple state datas to read and write
-- @param required_compnt_state_data component state datas to read and write
-- @tparam function run the function will be executed by this system
-- @treturn system
function M.new_system(required_simple_state_data, required_compnt_state_data, run)
  -- That way, we can use "false" for no read and write simple state_data
  if not required_simple_state_data then
    required_simple_state_data = {{}, {}}
  end

  -- That way, we can use "false" for no read and write components state_data
  if not required_compnt_state_data then
    required_compnt_state_data = {{}, {}}
  end

  local simple_state_data_reads  = required_simple_state_data[1] or {}
  local simple_state_data_writes = required_simple_state_data[2] or {}

  local compnt_state_data_reads  = required_compnt_state_data[1] or {}
  local compnt_state_data_writes = required_compnt_state_data[2] or {}

  local simple_state_data_needs = combine_arrays(simple_state_data_reads, simple_state_data_writes)
  local compnt_state_data_needs = combine_arrays(compnt_state_data_reads, compnt_state_data_writes)

  local all_needs  = combine_arrays(simple_state_data_needs, compnt_state_data_needs)
  local all_reads  = combine_arrays(simple_state_data_reads, compnt_state_data_reads)
  local all_writes = combine_arrays(simple_state_data_writes, compnt_state_data_writes)

  local new_system = {
    all_reads  = all_reads,
    all_writes = all_writes,
    all_needs  = all_needs,

    component_reads  = compnt_state_data_reads,
    component_writes = compnt_state_data_writes,
    component_needs  = compnt_state_data_needs,

    simple_state_data_reads  = simple_state_data_reads,
    simple_state_data_writes = simple_state_data_writes,
    simple_state_data_needs  = simple_state_data_needs,

    all_bit_filter = bit_ids.new_bit_filter(all_needs),
    compnt_state_data_bit_filter = bit_ids.new_bit_filter(compnt_state_data_needs),
    simple_state_data_bit_filter = bit_ids.new_bit_filter(simple_state_data_needs),

    run = run,
    components_ids_to_iterate = {}
  }

  return new_system
end

--- Updates the components ids to iterate when runs
-- , needed when an entity is deleted, but Motor handles that automatically, only necessary 
-- to run outside before the first state's run
-- @tparam system system system to update components ids
-- @tparam {storages.entry} entities_entries entities entries in the entities storage
-- @see main.lua
-- @usage
-- -- unfortunately this is still necessary before the first state's run
-- -- get main_state's entities storage
-- local entities_storage = main_state.state_data[main_state.entities_state_data_bit_id]
-- 
-- -- for each step, for each system in this step, update components ids to iterate
-- for step_i = 1, #main_state.systems do
--   local step = main_state.systems[step_i]
-- 
--   for system_i = 1, #step do
--     systems.update_components_ids_to_iterate(step[system_i], entities_storage.entries)
--   end
-- end
function M.update_components_ids_to_iterate(system, entities_entries)
  local components_ids_to_system = {}

  -- for each entity entry
  for entities_i = 1, #entities_entries do
    local entity_entry = entities_entries[entities_i]

    -- if entry is valid and alive
    if entity_entry and entity_entry[3] then
      local entity = entity_entry[2]
      
      -- does this entity contains the required components?      
      if bit_ids.contains_bit_ids(entity.state_data_bit_filter, system.compnt_state_data_bit_filter) then

        -- then we will get the ids of the associated components
        local components_tuple = {}

        -- for each state data bit_id needs of a system
        for system_needs_i = 1, #system.component_needs do

          -- for each associated state_data bit_id of an entity
          for entity_associated_state_data_bit_ids_i=1, #entity.associated_state_data_bit_ids do
            local associated_state_data_bit_id =
              entity.associated_state_data_bit_ids[entity_associated_state_data_bit_ids_i]

            -- is this associated_state_data_bit_id one of the components_ids that the system needs?
            if bit_ids.equals(associated_state_data_bit_id, system.component_needs[system_needs_i]) then

              -- insert associated component entry id in components_tuple
              -- index of associated components and associated state_data ids is the same :)
              table_insert(
                components_tuple,
                entity.associated_components_entries_ids[entity_associated_state_data_bit_ids_i]
              )
              break
            end
          end
        end

        if #components_tuple > 0 then
          table_insert(components_ids_to_system, components_tuple)
        end
      end
    end
  end

  system.components_ids_to_iterate = components_ids_to_system
end

return M
