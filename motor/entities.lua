--- entities
-- @module entities
local M = {}

local bit_ids = require 'motor.bit_ids'

--- entity table record
-- @table entity
-- @tfield bit_ids.bit_filter state_data_bit_filter
-- @tfield {id} associated_components_entries_ids array of ids
-- @tfield {bit_ids.bit_id} associated_state_data_bit_ids array of @{bit_ids.bit_id}s of the asssociated components
-- @see bit_ids.bit_id
-- @see bit_ids.bit_filter

--- Creates a new entity data.
-- @return entity
function M.new_entity()
  return {
    state_data_bit_filter = bit_ids.new_bit_filter(),
    associated_components_entries_ids = {},
    associated_state_data_bit_ids = {},
  }
end

--- find index of an associated id in the entity
-- @tparam entity entity
-- @tparam storages.id id id to find
-- @treturn integer index
function M.find_associated_id(entity, id)
  for i = 1, #entity.associated_components_entries_ids do
    local entity_entry_id = entity.associated_components_entries_ids[i]
    
    if entity_entry_id[1] == id[1] and entity_entry_id[2] == id[2]  then
      return i
    end
  end
  
  error("component_entry_id not found in the entity's associated_components_entries ids")
end

--- find index of an associated bit id in the entity
-- @tparam entity entity
-- @tparam bit_ids.bit_id bit_id bit_id to find
-- @treturn integer index
function M.find_associated_bit_id(entity, bit_id)
  for i = 1, #entity.associated_state_data_bit_ids do
    if bit_ids.equals(entity.associated_state_data_bit_ids[i], bit_id) then
      return i
    end
  end
  
  error("component_state_data_bit_id not found in the entity's associated_state_data_bit_ids")
end

--- Associate a entity with a component entry id and a state data bit id.
-- @tparam entity entity entity to apply association
-- @param component_entry_id component entry id
-- @tparam bit_ids.bit_id component_state_data_bit_id component state_data bit id
-- @see entity
-- @see disassociate_component
-- @see bit_ids.bit_id
-- @see example.lua
-- @usage
-- -- (see example.lua file example)
-- local entities = require 'motor.entities'
-- 
-- -- (...)
-- 
-- -- create a new name entry in names storage
-- local new_name_id = storages.new_entry(
--   main_state.state_data[names_state_data_id],
--   name_constructor("Hero Player")
-- )
-- 
-- -- get entities storages from the state
-- local entities_storage = main_state.state_data[main_state.entities_state_data_bit_id]
-- 
-- -- create a new entity entry in entities storage
-- local new_entity_id = storages.new_entry(
--   entities_storage,
--   entities.new_entity()
-- )
--
-- -- get the entry of the created entity
-- local entry_of_new_entity = storages.get_entry_content(entities_storage, new_entity_id)
-- 
-- -- associate with component
-- entities.associate_component(
--   entry_of_new_entity,
--   new_name_id,
--   names_state_data_id
-- )
function M.associate_component(entity, component_entry_id, component_state_data_bit_id)
  bit_ids.add_in_bit_filter(entity.state_data_bit_filter, component_state_data_bit_id)
  table.insert(entity.associated_components_entries_ids, component_entry_id)
  table.insert(entity.associated_state_data_bit_ids, component_state_data_bit_id)
end

--- Disassociate entity from components (not tested)
-- @tparam entity entity entity to apply disassociation
-- @param component_entry_id component entry id
-- @tparam bit_ids.bit_id component_state_data_bit_id component state_data bit id
-- @see entity
-- @see associate_component
-- @see bit_ids.bit_id
-- @usage
-- local entities = require 'motor.entities'
-- 
-- -- (...) (see associate_component example)
--  
-- entities.disassociate_component(
--   entry_of_new_entity,
--   new_name_id
--   names_state_data_id
-- )
function M.disassociate_component(entity, component_entry_id, component_state_data_bit_id)
  bit_ids.remove_in_bit_filter(entity.state_data_bit_filter, component_state_data_bit_id)
  table.remove(entity.associated_components_entries_ids, M.find_associated_id(entity, component_entry_id))
  table.remove(entity.associated_state_data_bit_ids, M.find_associated_bit_id(entity, component_state_data_bit_id))
end

return M
