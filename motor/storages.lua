--- storages
-- @module storages
local M = {}


--- id table record
--
-- some description
-- @table id
-- @tfield integer 1 index in table, where the content is localized in @{entry|entries} array table,
-- @tfield integer 2 generation

--- entry table record
-- @table entry
-- @tfield id 1 id
-- @tfield entry 2 entry content any value, is the entry content
-- @tfield boolean 3 is alive


--- storage table record
-- @table storage
-- @tfield integer free_ids_len quantity of free ids to be reused, initially 0
-- @tfield {ids} free_ids array table of free ids that can be reused
-- @tfield entry entries

--- create a new ID data
local function new_id_data(storage)
  return {#storage.entries+1, 1}
end

--- create a new ENTRY data
local function new_entry_data(id, entry_content)
  return {id, entry_content, true}
end

local function insert_entry_in_storage_entries(storage, entry)
  local id = entry[1]
  storage.entries[id[1]] = entry
end

--- create a new storage, used externally
-- @treturn storage
-- @usage
-- local storages = require 'motor.storages'
--
-- -- create a storage
-- local my_storage_id = storages.new_storage()
function M.new_storage()
  return {
    free_ids_len = 0,
    free_ids = {},
    entries = {},
    -- TODO: entries_ids = {}, and remove ids fields in entries
    -- TODO: alive_ids = {}, and remove alive fields in entries
  }
end

--- create a new entry in storage, uses a free id and entry space if possible
-- @tparam storage storage storage to add the new entry
-- @param new_entry_content any value, the content of this entry
-- @treturn id id of the new entry
-- @see entry
-- @usage
-- -- require 'storages'
-- local storages = require 'motor.storages'
--
-- -- create a new storage
-- local my_storage_id = storages.new_storage()
--
-- -- create a new entry in this storage, with content "10"
-- local my_entry_id = storages.new_entry(my_storage_id, 10)
function M.new_entry(storage, new_entry_content)
  -- is there any free id?
  if storage.free_ids_len > 0 then
    -- get last free id
    local recycled_id = storage.free_ids[storage.free_ids_len]

    -- increment generation of the recycled id
    recycled_id[2] = recycled_id[2] + 1

    -- remove last free id
    table.remove(storage.free_ids)

    -- decrement free ids lenght
    storage.free_ids_len = storage.free_ids_len - 1

    local new_entry = new_entry_data(recycled_id, new_entry_content)

    -- new entry
    insert_entry_in_storage_entries(storage, new_entry)

    -- return the id of the new entry
    return recycled_id
  else -- no free id, so, allocate a new entry
    -- create new id data and entry data
    local new_id = new_id_data(storage)
    local new_entry = new_entry_data(new_id, new_entry_content)

    -- apply new entry in the last index of storage's entries
    -- (new_id[1] is the last index already)
    insert_entry_in_storage_entries(storage, new_entry)

    -- return the id of the new entry
    return new_id
  end
end

--- Get an entry of a storage
-- @tparam storage storage storage where the entry lives
-- @tparam id id the id of the entry
-- @treturn entry the entry
function M.get_entry(storage, id)
  -- get entry
  local entry = storage.entries[id[1]]

  -- only return entry if generation is equal
  return entry[1][2] == id[2]
    and entry
    or nil
end

--- Get content of an entry
-- @tparam storage storage storage of the entry
-- @tparam id id id of the entry
-- @return the entry's content
-- @see entry
-- @see get_entry
function M.get_entry_content(storage, id)
  return M.get_entry(storage, id)[2]
end

--- Kills an entry, but it will live in memory until @{delete_dead_entries} is run
-- @tparam storage storage storage where entry lives
-- @tparam id id entry's ID
-- @see delete_dead_entries
function M.kill_entry(storage, id)
  local entry = M.get_entry(storage, id)
  entry[3] = false
end

--- Deletes dead entries
-- , killed by @{kill_entry}, basically executes @{delete_entry} in dead entries,
-- returns if any entry has been deleted.
-- @tparam storage storage storage to delete dead entries
-- @treturn boolean true if any entry was deleted
-- @see kill_entry
function M.delete_dead_entries(storage)
  local some_entry_was_deleted = false

  -- iterate entries
  local entries = storage.entries
  for i = 1, #entries do
    local entry_i = entries[i]

    -- if this entry isn't alive
    if entry_i and not entry_i[3] then
      M.delete_entry(storage, entry_i[1])
      some_entry_was_deleted = true
    end
  end

  return some_entry_was_deleted
end

--- Delete an entry
-- , the index will be available for a new entry
-- generally you will use @{kill_entry} instead
-- @tparam storage storage storage where entry lives
-- @tparam id id entry's ID
-- @see kill_entry
function M.delete_entry(storage, id)
  -- delete entry
  storage.entries[id[1]] = false

  -- add a new free id
  table.insert(storage.free_ids, id)

  -- increment free id lenght
  storage.free_ids_len = storage.free_ids_len + 1
end

return M
