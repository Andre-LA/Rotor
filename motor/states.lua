--- states
-- @module states
local storages = require ("motor.storages")
local systems  = require ("motor.systems")
local bit_ids  = require ("motor.bit_ids")

--- Adds a new StateData in the StateData
-- @tparam StateData state the state to add a new state data
-- @param state_content_content state data content (what this state data actually is), state data can be any type of value
-- @treturn bit_ids.bit_id bit_id of the new state data
-- @see bit_ids.bit_id
local function add_state_content(state, state_content_content)
  state.last_state_content_bit_id = bit_ids.new_bit_id(state.last_state_content_bit_id)
  state.state_content[state.last_state_content_bit_id] = state_content_content
  return state.last_state_content_bit_id
end

--- Creates a new system step, a system step is a group of systems
-- , the next group only runs after the current group finishes
-- , for now, this is the only way to run systems in a sequential order
-- @tparam StateData state state to add systems step
-- @tparam {systems.System} systems_step  array of systems to run
-- @see systems.system
local function add_systems_step(state, systems_step)
  table.insert(state.steps, systems_step)
end

local State_mt = {
  __index = {
    add_state_content = add_state_content,
    add_systems_step = add_systems_step,
  }
}

--- the StateData record
-- @table StateData
-- @tfield {systems.System} steps contains all the steps in the StateData, each step is a group of systems
-- @tfield table state_content contains all the StateData in the StateData
-- @tfield bit_ids.bit_id last_state_content_bit_id last bit id used for state_content
-- @tfield bit_ids.bit_id entities_bit_id the bit id of the Storage of entities
local StateData = {
  new = function (steps, state_content, last_state_content_bit_id)
    local new_state_data = {
      steps = steps,
      state_content = state_content,
      last_state_content_bit_id = last_state_content_bit_id,
      entities_bit_id = false -- will be overwritten below
    }

    new_state_data.entities_bit_id = add_state_content(new_state_data, storages.new_init_storage())

    setmetatable(new_state_data, State_mt)

    return new_state_data
  end
}

local function new_init_state_data()
  return StateData.new({}, {}, bit_ids.new_bit_filter())
end

return {
  StateData = StateData,
  new_init_state_data = new_init_state_data,
  add_state_content = add_state_content,
  add_systems_step = add_systems_step
}

