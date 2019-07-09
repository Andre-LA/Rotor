--- system_data library
-- @module system_data

local bitset_array = require "bitset_array"
local storage = require "storage"

local table_insert = table.insert
local _unpack = require 'lua5x-operations'.unpack

local function union(a, b)
  local t, a_len = {}, #a
  for i = 1, #a do t[i] = a[i] end
  for i = 1, #b do t[i+a_len] = b[i] end
  return t
end
-- : (read {value:value}, read {value:value}) -> new {value:value}

--- updates the system data
-- @function update
-- @tparam system_data system_data system data to update
-- @tparam storage entities_storage
local function update(system_data, entities_storage)
  local indexes = {}

  -- iterate over entities
  for entity in storage.iterate_entries(entities_storage) do
    local masks_intersection = bitset_array.band(entity.mask, system_data.mask)

    -- if this entity is associated with the required storages
    if bitset_array.equals(masks_intersection, system_data.mask) then
      local components_tuple = {}

      -- for each required storage, insert the components indexes respectively
      for i = 1, #system_data.required_storages do
        for j = 1, #entity.associated_storages do
          if bitset_array.equals(
            system_data.required_storages[i],
            entity.associated_storages[j]
          )
          then
            table_insert(components_tuple, entity.associated_components[i])
          end
        end
      end

      if #components_tuple > 0 then
        table_insert(indexes, components_tuple)
      end
    end
  end

  system_data.components_indexes = indexes
end
-- : (write system_data, read storage) -> nil

--- get components in the same order as passed in @{new} function
-- @function get_components
-- @tparam system_data system_data
-- @tparam {storages} storages to get components,
-- should be in the same order as passed in @{new} function
-- @tparam integer idx index components_indexes
-- @return table of components, in the same order as passed in @{new} function
local function get_components(system_data, storages, idx)
  local results = {}

  local components_indexes = system_data.components_indexes[idx]

  if not components_indexes then
    return nil, "invalid index"
  end

  for i = 1, #components_indexes do
    local component_value = storage.get_entry(
      storages[i],
      components_indexes[i]
    )
    results[i] = component_value
  end

  return results
end
-- : (read system_data, read {storage}, integer) -> {value} or nil, string

--- iterates over components
-- @function iterate_components
-- @tparam system_data system_data
-- @tparam {storage} storages, in the same order as passed in @{new} function
-- @tparam boolean should_unpack if false, returns a table
-- @treturn func components iterator
local function iterate_components(system_data, storages, should_unpack)
  local i = 0
  local limit = #system_data.components_indexes

  return function() -- iterator
    i = i + 1

    if i > limit then
      return nil
    else
      local components_values = get_components(system_data, storages, i)

      if components_values then
        if should_unpack then
          return _unpack(components_values)
        else
          return components_values
        end
      end
    end
  end
end
-- : (read system_data, read {storage}, boolean) -> () -> {value} or nil

local methods = {
  update = update,
  get_components = get_components,
  iterate_components = iterate_components
}

local system_data_mt = {
  __index = methods
}

--- creates a new system_data table
-- @function new
-- @tparam {bitset_array}  read_components components that
-- are read by the system
-- @tparam {bitset_array}  write_components components that
-- are written by the system
-- @treturn system_data
local function new(read_components, write_components)
  local mask_read, mask_write = bitset_array.new(), bitset_array.new()

  if not write_components then
    write_components = {}
  end

  for i = 1, #read_components do
    mask_read = bitset_array.bor(mask_read, read_components[i])
  end
  for i = 1, #write_components do
    mask_write = bitset_array.bor(mask_write, write_components[i])
  end

  local new_system_data = {
    mask = bitset_array.bor(mask_read, mask_write),
    mask_write = mask_write,
    required_storages = union(read_components, write_components),
    components_indexes = {}
  }

  setmetatable(new_system_data, system_data_mt)
  return new_system_data
end
-- : (read {bitset_array}, read {bitset_array}) -> new system_data

--[[
  system_data: {
    mask: bitset_array,
    write_mask: bitset_array,
    required_storages: {bitset_array}
    components_indexes: {{generational_index}}
  }
--]]

--- system_data table
-- @tfield bitset_array mask
-- @tfield bitset_array write_mask
-- @tfield {bitset_array} required_storages
-- @tfield {{generational_index}} components_indexes
-- @table system_data

return {
  new = new,
  -- : ({bitset_array} [, {bitset_array}]) -> new system_data

  update = update,
  -- : (write system_data, read storage) -> nil

  get_components = get_components,
  -- : (read system_data, read {storage}, integer) -> {value} or nil, string

  iterate_components = iterate_components,
  -- : (read system_data, read {storage}, boolean) -> () -> {value} or nil
}
