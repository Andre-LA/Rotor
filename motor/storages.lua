--- storages
-- @module storages

--- Id record
-- Generational Id
-- @table Id
-- @tfield integer index index in table, where the content is localized in @{entry|entries} array table,
-- @tfield integer generation generation of this index (how many times this index was used)
local Id = {
  new = function(index, generation)
    return {
      index = index or 1,
      generation = generation or 0
    }
  end
}

--- Entry record
-- @table Entry
-- @tfield Id id
-- @field content any value, is the entry content
-- @tfield boolean is_alive
local Entry = {
  new = function(id, content, is_alive)
    return {
      id = id,
      content = content,
      is_alive = true
    }
  end
}

--- create a new entry in storage, uses a free id and entry space if possible
-- @tparam Storage storage storage to add the new entry
-- @param new_entry_content any value, the content of this entry
-- @treturn Id id of the new entry
-- @see Entry
-- @usage
-- -- require 'storages'
-- local storages = require 'motor.storages'
--
-- -- create a new storage
-- local my_storage_id = storages.new_storage()
--
-- -- create a new entry in this storage, with content "10"
-- local my_entry_id = storages.new_entry(my_storage_id, 10)
local function new_entry(storage, new_entry_content)
  -- is there any free id?
  if storage.free_ids_len > 0 then
    -- get last free id
    local recycled_id = storage.free_ids[storage.free_ids_len]

    -- increment generation of the recycled id
    recycled_id.generation = recycled_id.generation + 1

    -- remove last free id
    table.remove(storage.free_ids)

    -- decrement free ids lenght
    storage.free_ids_len = storage.free_ids_len - 1

    local new_entry_data = Entry.new(recycled_id, new_entry_content)

    -- new entry
    storage.entries[new_entry_data.id.index] = new_entry_data

    -- return the id of the new entry
    return recycled_id
  else -- no free id, so, allocate a new entry
    -- create new id data and entry data
    local new_id = Id.new(#storage.entries + 1, 1)
    local new_entry_data = Entry.new(new_id, new_entry_content)

    -- apply new entry in the last index of storage's entries
    -- (new_entry_data.id.index is the last index already)
    storage.entries[new_entry_data.id.index] = new_entry_data

    -- return the id of the new entry
    return new_id
  end
end

--- Get an entry of a storage
-- @tparam storage storage storage where the entry lives
-- @tparam id id the id of the entry
-- @treturn entry the entry
local function get_entry(storage, id)
  local entry = storage.entries[id.index]

  if not entry then
    return nil, "entry not found"
  elseif entry.id.generation ~= id.generation then
    return nil, "entry not found (an entry was found by index, but it's from an another generation)"
  end

  return entry
end

--- Kills an entry, but it will live in memory until @{delete_dead_entries} is run
-- @tparam Storage storage storage where entry lives
-- @tparam Id id entry's ID
-- @see delete_dead_entries
local function kill_entry(storage, id)
  get_entry(storage, id).is_alive = false
end

--- Delete an entry
-- , the index will be available for a new entry
-- generally you will use @{kill_entry} instead
-- @tparam storage storage storage where entry lives
-- @tparam id id entry's ID
-- @see kill_entry
local function delete_entry(storage, id)
  -- delete entry content
  storage.entries[id.index].content = nil

  -- add a new free id
  table.insert(storage.free_ids, id)

  -- increment free id lenght
  storage.free_ids_len = storage.free_ids_len + 1
end

--- Deletes dead entries
-- , killed by @{kill_entry}, basically executes @{delete_entry} in dead entries,
-- returns if any entry has been deleted.
-- @tparam storage storage storage to delete dead entries
-- @treturn boolean true if any entry was deleted
-- @see kill_entry
local function delete_dead_entries(storage)
  local some_entry_was_deleted = false

  local entries = storage.entries

  for i = 1, #entries do
    -- if this entry isn't alive
    if not entries[i].is_alive then
      delete_entry(storage, entries[i].id)
      some_entry_was_deleted = true
    end
  end

  return some_entry_was_deleted
end

local State_mt = {
  __index = {
    new_entry  = new_entry,
    get_entry  = get_entry,
    kill_entry = kill_entry,
    delete_dead_entries = delete_dead_entries,
    delete_entry = delete_entry
  }
}
--- Storage record
-- @table Storage
-- @tfield integer free_ids_len quantity of free ids to be reused, initially 0
-- @tfield {Id} free_ids array table of free ids that can be reused
-- @tfield {Entry} entries
local Storage = {
  new = function(free_ids_len, free_ids, entries)
    local new_state_data = {
      free_ids_len =  free_ids_len,
      free_ids = free_ids,
      entries = entries,
      -- TODO: entries_ids = {}, and remove ids fields in entries
      -- TODO: alive_ids = {}, and remove alive fields in entries
    }

    setmetatable(new_state_data, State_mt)

    return new_state_data
  end
}

local function new_storage()
  return Storage.new(0, {}, {})
end

return {
  Storage = Storage,
  Id = Id,
  Entry = Entry,
  new_storage = new_storage,
  new_entry  = new_entry,
  get_entry  = get_entry,
  kill_entry = kill_entry,
  delete_dead_entries = delete_dead_entries,
  delete_entry = delete_entry
}
