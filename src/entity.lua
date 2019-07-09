--- entity library
-- @module entity

local bitset_array = require 'bitset_array'
local gen_id = require 'generational_index'

local table_insert, table_remove = table.insert, table.remove

local function find(list, value_to_find, eq_function, list_name)
  for i = 1, #list do
    if eq_function(list[i], value_to_find) then
      return i
    end
  end

  return nil, list_name .. " index not found"
end
-- : (read {id or bitset_array}, read generational_index)
--   -> integer or (nil, string)

--- gets the index of associated_components of this component
-- @function get_component_index
-- @tparam entity entity
-- @tparam generational_index component_gen_idx
-- @treturn integer|nil integer or nil, string
local function get_component_index(entity, component_gen_idx)
  return find(
    entity.associated_components,
    component_gen_idx,
    gen_id.equals,
    "component"
  )
end
-- : (read entity, read generational_index) -> integer or (nil, string)

--- gets the index of associated_storages of this storage mask
-- @function get_storage_index
-- @tparam entity entity
-- @tparam bitset_array storage_mask
-- @treturn integer|nil integer or nil, string
local function get_storage_index(entity, storage_mask)
  return find(
      entity.associated_storages,
      storage_mask,
      bitset_array.equals,
      "storage"
    )
end
-- : (read entity, read bitset_array) -> integer or (nil, string)

--- associates an component and it's storage mask
-- @function associate
-- @tparam entity entity
-- @tparam generational_index component_gen_idx
local function associate(entity, component_gen_idx, storage_mask)
  entity.mask = bitset_array.bor(entity.mask, storage_mask)
  table_insert(entity.associated_components, component_gen_idx)
  table_insert(entity.associated_storages, storage_mask)
end
-- : (write (entity), take (storage.id), take (bitset_array)) -> nil

--- disassociates an component and it's storage mask
-- @function disassociate
-- @tparam entity entity
-- @tparam generational_index|bitset_array component_gen_idx_or_storage_mask
-- @treturn boolean|nil returns true if succeedes; nil, string otherwise
local function disassociate(entity, component_gen_idx_or_storage_mask)
  local is_bitset_array = #component_gen_idx_or_storage_mask > 0

  local ok_index, err_msg =
    (is_bitset_array and get_storage_index or get_component_index) -- expression
    (entity, component_gen_idx_or_storage_mask) -- func call of previous expr

  if ok_index then
    entity.mask = bitset_array.band(
      entity.mask,
      bitset_array.bnot(entity.associated_storages[ok_index])
    )
    table_remove(entity.associated_components, ok_index)
    table_remove(entity.associated_storages, ok_index)
    return true
  else
    return nil, err_msg
  end
end
-- : (write entity, read generational_index or bitset_array)
-- -> boolean or nil, string

local entity_methods = {
  get_component_index = get_component_index,
  get_storage_index = get_storage_index,
  associate = associate,
  disassociate = disassociate
}

local entity_mt = {
  __index = entity_methods,
}

--- creates a new entity table
-- @function new
-- @treturn entity
local new = function ()
  local new_entity = {
    associated_components = {},
    associated_storages = {},
    mask = bitset_array.new()
  }

  setmetatable(new_entity, entity_mt)
  return new_entity
end
-- : () -> new entity

--[[
  entity: {
    associated_components: {generational_index},
    associated_storages: {bitset_array},
    mask: bitset_array
  }
]]

-- same as above, but for LDoc:

--- entity table
-- @tfield {generational_index} associated_components
-- @tfield {bitset_array} associated_storages
-- @tfield bitset_array mask
-- @table entity

return {
  new = new,
  -- : () -> new entity

  get_component_index = get_component_index,
  -- : (read entity, read generational_index) -> integer or nil, string
  get_storage_index = get_storage_index,
  -- : (read entity, read bitset_array) -> integer or nil, string
  associate = associate,
  -- : (write entity, take generational_index, take bitset_array) -> nil
  disassociate = disassociate,
  -- : (write entity, read generational_index or bitset_array)
  --   -> boolean or nil, string
}
