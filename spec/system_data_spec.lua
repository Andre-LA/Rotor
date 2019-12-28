local _unpack = unpack or table.unpack

-- luacov: disable
-- local inspect = require 'inspect'
-- local inspect_opt = {
--   process = function(item, path)
--     if path[#path] ~= inspect.METATABLE then return item end
--   end
-- }
-- local function print_inspect(v)
--   print(inspect(v, inspect_opt))
-- end
-- luacov: enable

-- Important note:
-- This is the most important test because it relies on
-- all other libraries to work and it's also the core of ECS.

describe("system_data library", function()
  local system_data = require "motor.system_data"
  local bitset_array = require "motor.bitset_array"
  local generational_index = require "motor.generational_index"
  local storage = require "motor.storage"
  local entity = require "motor.entity"

  -- components and system to use in tests
  local function new_position(x, y)
    return {x = x or 0, y = y or 0}
  end

  local function new_velocity(x, y)
    return {x = x or 0, y = y or 0}
  end

  local velocity_storage = storage.new()
  local velocity_mask = bitset_array.new(1, {1})

  local position_storage = storage.new()
  local position_mask = bitset_array.new(1, {1}):lshift(1)

  local entities_storage = storage.new()
  local entities_mask = bitset_array.new(1, {1}):lshift(2)

  local velocity_value = new_velocity(2, 4)
  local position_value = new_position(-3, -5)

  local velocity_component = velocity_storage:new_entry(velocity_value)
  local position_component = position_storage:new_entry(position_value)

  local mobile_entity = entity.new()
  local mobile_entity_id = entities_storage:new_entry(mobile_entity)

  mobile_entity:associate(velocity_component, velocity_mask)
  mobile_entity:associate(position_component, position_mask)

  describe("'new' function", function ()
    it ("can create a new system_data", function()
      local test_system_data = system_data.new({}, {})

      assert.are_same({
        mask = bitset_array.new(),
        mask_write = bitset_array.new(),
        required_storages = {},
        components_indexes = {},
        available_indexes = {},
      }, test_system_data)
    end)

    it ("2nd argument is optional", function()
      local test_system_data = system_data.new({})

      assert.are_same({
        mask = bitset_array.new(),
        mask_write = bitset_array.new(),
        required_storages = {},
        components_indexes = {},
        available_indexes = {},
      }, test_system_data)
    end)

    it ("can create a new system_data that describes the required components",
      function()
        local test_system_data = system_data.new({velocity_mask}, {position_mask})
        local bor = bitset_array.bor

        assert.are_same({
          mask = bor(velocity_mask, position_mask),
          mask_write = bor(bitset_array.new(), position_mask),
          required_storages = {velocity_mask, position_mask},
          components_indexes = {},
          available_indexes = {}
          -- components_indexes should be
          -- {{velocity_component, position_component}},
          -- but the update function needs to be run before
        }, test_system_data)
      end)
    end)

  describe("'update' function", function()
    local function assert_test(test_system_data)
      local bor = bitset_array.bor

      assert.are_same({
          mask = bor(velocity_mask, position_mask),
          mask_write = bor(bitset_array.new(), position_mask),
          required_storages = {velocity_mask, position_mask},
          components_indexes = {{velocity_component, position_component}},
          available_indexes = {}
        }, test_system_data)
    end

    it ("updates the associated generational indexes of the components",
    function()
      local test_system_data = system_data.new({velocity_mask}, {position_mask})
      system_data.update(test_system_data, entities_storage, {mobile_entity_id})
      assert_test(test_system_data)
    end)

    it ("can be used as method", function ()
      local test_system_data = system_data.new({velocity_mask}, {position_mask})
      test_system_data:update(entities_storage, {mobile_entity_id})
      assert_test(test_system_data)
    end)
  end)

  it("get components", function()
    local test_system_data = system_data.new({velocity_mask}, {position_mask})
    system_data.update(test_system_data, entities_storage, {mobile_entity_id})

    local ids = test_system_data.components_indexes[1]

    assert.is_truthy(ids)

    local e_velocity = velocity_storage:get_entry(ids[1])
    local e_position = position_storage:get_entry(ids[2])

    assert.are_same(velocity_value, e_velocity)
    assert.are_same(position_value, e_position)
  end)

  it("is used to make systems", function ()
    local function movement_system (arg_system_data)
      for i = 1, #arg_system_data.components_indexes do
        local ids = arg_system_data.components_indexes[i]

        if ids then
          local vel_id, pos_id = ids[1], ids[2]

          local position = position_storage:get_entry(pos_id)
          local velocity = velocity_storage:get_entry(vel_id)

          position.x = position.x + velocity.x
          position.y = position.y + velocity.y

          assert.are_same({x = -1, y = -1}, position)
        end
      end
    end

    local test_system_data = system_data.new({velocity_mask}, {position_mask})
    system_data.update(test_system_data, entities_storage, {mobile_entity_id})
    movement_system(test_system_data, velocity_storage, position_storage)
  end)
end)
