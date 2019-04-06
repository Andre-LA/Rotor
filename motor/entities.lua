--- entities
-- @module entities

local bit_ids = require ("motor.bit_ids")

--- find index of an associated id in the entity
-- @tparam EntityData entity
-- @tparam Storages.Id id id to find
-- @treturn integer index
local function find_associated_id(entity, id)
  for i = 1, #entity.associated_components_entries_ids do
    local entity_entry_id = entity.associated_components_entries_ids[i]

    if entity_entry_id.index == id.index and entity_entry_id.generation == id.generation then
      return i
    end
  end

  return nil, "associated id not found"
end

--- find index of an associated bit id in the entity
-- @tparam EntityData entity
-- @tparam bit_ids.bit_id bit_id bit_id to find
-- @treturn integer index
local function find_associated_bit_id(entity, bit_id)
  for i = 1, #entity.associated_state_content_bit_ids do
    if bit_ids.equals(entity.associated_state_content_bit_ids[i], bit_id) then
      return i
    end
  end

  return nil, "associated bit id not found"
end


--- Associate a entity with a component entry id and a state data bit id.
-- @tparam EntityData entity entity to apply association
-- @tparam Storages.Id component_entry_id component entry id
-- @tparam bit_ids.bit_id component_state_content_bit_id component state_content bit id
-- @see EntityData
-- @see disassociate_component
-- @see bit_ids.bit_id
-- @usage
-- -- (see example.lua file example)
-- local entities = require 'motor.entities'
--
-- -- (...)
--
-- -- create a new name entry in names storage
-- local new_name_id = storages.new_entry(
--   main_state.state_content[names_state_content_id],
--   name_constructor("Hero Player")
-- )
--
-- -- get entities storages from the state
-- local entities_storage = main_state.state_content[main_state.entities_state_content_bit_id]
--
-- -- create a new entity entry in entities storage
-- local new_entity_id = storages.new_entry(
--   entities_storage,
--   entities.new_init_entity()
-- )
--
-- -- get the entry of the created entity
-- local entry_of_new_entity = storages.get_entry_content(entities_storage, new_entity_id)
--
-- -- associate with component
-- entities.associate_component(
--   entry_of_new_entity,
--   new_name_id,
--   names_state_content_id
-- )
local function associate_component(entity, component_entry_id, component_state_content_bit_id)
  bit_ids.add_in_bit_filter(entity.state_content_bit_filter, component_state_content_bit_id)
  table.insert(entity.associated_components_entries_ids, component_entry_id)
  table.insert(entity.associated_state_content_bit_ids, component_state_content_bit_id)
end

--- Disassociate entity from components (not tested)
-- @tparam EntityData entity entity to apply disassociation
-- @tparam Storages.Id component_entry_id component entry id
-- @tparam bit_ids.bit_id component_state_content_bit_id component state_content bit id
-- @see EntityData
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
--   names_state_content_id
-- )
local function disassociate_component(entity, component_entry_id, component_state_content_bit_id)
  bit_ids.remove_in_bit_filter(entity.state_content_bit_filter, component_state_content_bit_id)
  table.remove(entity.associated_components_entries_ids, entity:find_associated_id(component_entry_id))
  table.remove(entity.associated_state_content_bit_ids, entity:find_associated_bit_id(component_state_content_bit_id))
end

local Entity_mt = {
  __index = {
    find_associated_id     = find_associated_id,
    find_associated_bit_id = find_associated_bit_id,
    associate_component    = associate_component,
    disassociate_component = disassociate_component
  }
}

--- EntityData record
-- @table EntityData
-- @tfield bit_ids.bit_filter state_content_bit_filter
-- @tfield {id} associated_components_entries_ids array of ids
-- @tfield {bit_ids.bit_id} associated_state_content_bit_ids array of @{bit_ids.bit_id}s of the asssociated components
-- @see bit_ids.bit_id
-- @see bit_ids.bit_filter
local EntityData = {
  new = function (state_content_bit_filter, associated_components_entries_ids, associated_state_content_bit_ids)
    local new_entity_data = {
      state_content_bit_filter = state_content_bit_filter,
      associated_components_entries_ids = associated_components_entries_ids,
      associated_state_content_bit_ids = associated_state_content_bit_ids
    }

    setmetatable(new_entity_data, Entity_mt)

    return new_entity_data
  end
}

local function new_init_entity()
  return EntityData.new(bit_ids.new_bit_filter(), {}, {})
end

return {
  EntityData = EntityData,
  new_init_entity = new_init_entity,
  find_associated_id     = find_associated_id,
  find_associated_bit_id = find_associated_bit_id,
  associate_component    = associate_component,
  disassociate_component = disassociate_component
}
