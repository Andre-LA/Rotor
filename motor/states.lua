--- states
-- @module states
local storages = require 'motor.storages'
local systems = require  'motor.systems'
local bit_ids = require  'motor.bit_ids'

--- Adds a new StateData in the State
-- @tparam State state the state to add a new state data
-- @param state_data_content state data content (what this state data actually is), state data can be any type of value
-- @treturn bit_ids.bit_id bit_id of the new state data
-- @see bit_ids.bit_id
local function add_state_data(state, state_data_content)
  state.last_state_data_bit_id = bit_ids.new_bit_id(state.last_state_data_bit_id)
  state.state_data[state.last_state_data_bit_id] = state_data_content
  return state.last_state_data_bit_id
end

--- Creates a new system step, a system step is a group of systems
-- , the next group only runs after the current group finishes
-- , for now, this is the only way to run systems in a sequential order
-- @tparam State state state to add systems step
-- @tparam {systems.System} systems_step  array of systems to run
-- @see systems.system
local function add_systems_step(state, systems_step)
  table.insert(state.systems, systems_step)
end

--- Run the systems of the state
-- , more specifically, each systems step sequentially
-- @tparam State state state to run
-- @see state
local function run(state)
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

local State_mt = {
  __index = {
    add_state_data = add_state_data,
    add_systems_step = add_systems_step,
    run = run,
  }
}

--- the State record
-- @table state
-- @tfield {systems.System} systems contains all the systems in the State
-- @tfield table state_data contains all the StateData in the State
-- @tfield bit_ids.bit_id last_state_data_bit_id last bit id used for state_data
-- @tfield bit_ids.bit_id entities_state_data_bit_id the bit id of the Storage of entities
local State = {
  new = function (systems, state_data, last_state_data_bit_id)
    local new_state_data = {
      systems = systems,
      state_data = state_data,
      last_state_data_bit_id = last_state_data_bit_id,
      entities_state_data_bit_id = false -- will be overwritten below
    }

    new_state_data.entities_state_data_bit_id = add_state_data(new_state_data, storages.new_storage())

    setmetatable(new_state_data, State_mt)

    return new_state_data
  end
}

local function new_state()
  return State.new({}, {}, bit_ids.new_bit_filter())
end

return {
  State = State,
  new_state = new_state,
  add_state_data = add_state_data,
  add_systems_step = add_systems_step,
  run = run,
}

