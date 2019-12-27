--- storage library
-- @module storage

local generational_index = require 'motor.generational_index'
local new_id = generational_index.new
-- :/alias gen_idx = generational_index

local function try_get_entry_gen_idx(storage, gen_idx)
   local entry_generation = storage.generations[gen_idx.index]

   if not entry_generation or gen_idx.generation ~= entry_generation then
      return nil, "entry not found"
   end

   return gen_idx
end
-- :(read storage, read gen_idx) -> new gen_idx or nil, string

--- inserts a new entry in the storage
-- @function new_entry
-- @tparam storage storage
-- @param entry_content value to insert
-- @treturn generational_index
local function new_entry(storage, entry_content)
   local next_free_ids = storage.next_free_ids -- ref
   local next_free_ids_len = #next_free_ids

   local last_free_id = next_free_ids[next_free_ids_len] -- ref

   local entry_index = last_free_id.index
   local entry_generation = last_free_id.generation

   storage.entries[entry_index] = entry_content
   storage.generations[entry_index] = entry_generation

   if entry_index > storage.len then -- storage needs to grow
      storage.len = entry_index -- assert(entry_index == storage.len + 1)
      last_free_id.index = entry_index + 1
      last_free_id.generation = 0
   else
      table.remove(next_free_ids)
   end

   -- return a copy of the gen_idx of this new entry
   return new_id(entry_index, entry_generation)
end
-- : (write storage, take value) -> new gen_idx

--- gets an entry
-- @function get_entry
-- @tparam storage storage
-- @tparam generational_index gen_idx generational index of the entry
-- @return value or nil, string
local function get_entry(storage, gen_idx)
   local ok_entry_gen_idx, err_msg = try_get_entry_gen_idx(storage, gen_idx)

   if ok_entry_gen_idx then
      return storage.entries[ok_entry_gen_idx.index]
   else
      return nil, err_msg
   end
end
-- : (read storage, read gen_idx) -> value or (nil, string)

--- removes an entry by it's generational index
-- @function remove_entry
-- @tparam storage storage
-- @tparam generational_index gen_idx generational index of the entry
-- @treturn boolean|nil returns true or nil, string
local function remove_entry(storage, gen_idx)
   local ok_entry_gen_idx, err_msg = try_get_entry_gen_idx(storage, gen_idx)
   if not ok_entry_gen_idx then
      return nil, err_msg
   end

   storage.entries[ok_entry_gen_idx.index] = nil
   storage.generations[ok_entry_gen_idx.index] = nil

   if ok_entry_gen_idx.index == storage.len then
      local last_i = 0
      for i=1, storage.len do
         if storage.generations[i] then
            last_i = i
         end
      end
      storage.len = last_i
   end

   table.insert(
      storage.next_free_ids,
      new_id(ok_entry_gen_idx.index, ok_entry_gen_idx.generation + 1)
   )

  return true
end
-- : (write storage, read gen_idx) -> boolean or (nil, string)

--- iterate over entries
-- @function iterate_entries
-- @tparam storage storage
-- @treturn func iterator function
local function iterate_entries(storage)
   local i, entries_len, entry_id = 0, storage.len, new_id(0, 0)

   return function ()
      local ok_entry;
      while ok_entry == nil and i < entries_len do
         i = i + 1
         entry_id.index, entry_id.generation = i, (storage.generations[i] or -1)
         ok_entry = get_entry(storage, entry_id)
      end
      return ok_entry
   end
end
-- read storage -> () -> value or nil

local storage_methods = {
   new_entry = new_entry,
   get_entry = get_entry,
   remove_entry = remove_entry,
   iterate_entries = iterate_entries
}

local storage_mt = {
   __index = storage_methods,
}

--- creates a new storage table
-- @function new
-- @treturn storage
local function new ()
   local new_storage = {
      next_free_ids = {new_id(1, 0)},
      entries = {},
      generations = {},
      len = 0
   } -- : storage

   setmetatable(new_storage, storage_mt)

   return new_storage
end

--[[
   storage: {
      next_free_ids: {gen_idx},
      entries: {value},
      generations: {integer},
      len: integer,
   }
--]]

--- storage table
-- @tfield {generational_index} next_free_ids
-- @field entries -- array of values
-- @tfield {integer} generations
-- @tfield integer len
-- @table storage

return {
   new = new,
   -- : () -> new storage

   new_entry = new_entry,
   -- : (write storage, value) -> new gen_idx
   get_entry = get_entry,
   -- : (read storage, read gen_idx) -> value or (nil, string)
   remove_entry = remove_entry,
   -- : (write storage, read gen_idx) -> boolean or (nil, string)
   iterate_entries = iterate_entries
   -- : read storage -> () -> value or nil
}
