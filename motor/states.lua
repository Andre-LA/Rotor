--- states
-- @module states
local M = {}

local table_insert = table.insert

local storages = require 'motor.storages'
local systems = require 'motor.systems'
local bit_ids = require 'motor.bit_ids'

--- the states table
-- @table state
-- @tfield table systems contains all the systems in the State
-- @tfield table state_data contains all the StateData in the State
-- @tfield number last_state_data_bit_id last bit id used for state_data
-- @tfield number entities_state_data_bit_id the bit id of the Storage of entities

--- Creates a new state
-- @treturn state
function M.new_state()

  local new_state = {
    systems = {},
    state_data = {},
    last_state_data_bit_id = bit_ids.new_bit_id(),
    entities_state_data_bit_id = 0
  }

  new_state.entities_state_data_bit_id = M.add_state_data(new_state, storages.new_storage())
  return new_state
end

--- Adds a new StateData in the State
-- @tparam state state the state to add a new state data
-- @param state_data_content state data content (what this state data actually is), state data can be any type of value
-- @treturn bit_ids.bit_id bit_id of the new state data
-- @see bit_ids.bit_id
function M.add_state_data(state, state_data_content)
  state.last_state_data_bit_id = bit_ids.new_bit_id(state.last_state_data_bit_id)

  -- not sure about this, because will be a hash :|
  state.state_data[state.last_state_data_bit_id] = state_data_content

  return state.last_state_data_bit_id
end

--- Creates a new system step, a system step is a group of systems
-- , the next group only runs after the current group finishes
-- , for now, this is the only way to run systems in a sequential order
-- @tparam state state state to add systems step
-- @tparam {systems.system} systems_step  array of systems to run
-- @see systems.system
function M.new_systems_step(state, systems_step)
  table_insert(state.systems, systems_step)
end

--- Run the systems of the state
-- , more specifically, each systems step sequentially
-- @tparam state state state to run
-- @see state
function M.run(state)
  local entities_storage = state.state_data[state.entities_state_data_bit_id]

  -- for each step in systems
  for step_i = 1, #state.systems do
    local step = state.systems[step_i]

    -- for each system in steps
    for system_i = 1, #step do
      local system = step[system_i]

      -- clear entries and update systems if necessary
      if storages.delete_dead_entries(entities_storage) then
        systems.update_components_ids_to_iterate(system, entities_storage.entries)
      end

      -- run the system
      system.run(state.state_data, system.simple_state_data_needs, system.components_ids_to_iterate)
    end
  end
end

return M

