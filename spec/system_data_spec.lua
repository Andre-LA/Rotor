local _unpack = unpack or table.unpack

-- luacov: disable
local inspect = require 'inspect'
local inspect_opt = {
  process = function(item, path)
    if path[#path] ~= inspect.METATABLE then return item end
  end
}
local function print_inspect(v)
  print(inspect(v, inspect_opt))
end
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
  local _ = entities_storage:new_entry(mobile_entity)

  mobile_entity:associate(velocity_component, velocity_mask)
  mobile_entity:associate(position_component, position_mask)

  describe("'new' function", function ()
    it ("can create a new system_data", function()
      local test_system_data = system_data.new({}, {})

      assert.are_same({
        mask = bitset_array.new(),
        mask_write = bitset_array.new(),
        required_storages = {},
        components_indexes = {}
      }, test_system_data)
    end)

    it ("2nd argument is optional", function()
      local test_system_data = system_data.new({})

      assert.are_same({
        mask = bitset_array.new(),
        mask_write = bitset_array.new(),
        required_storages = {},
        components_indexes = {}
      }, test_system_data)
    end)

    it ("can create a new system_data that describes the required components",
      function()
        local test_system_data = system_data.new(
          {velocity_mask}, {position_mask}
        )

        local bor = bitset_array.bor

        assert.are_same({
          mask = bor(velocity_mask, position_mask),
          mask_write = bor(bitset_array.new(), position_mask),
          required_storages = {velocity_mask, position_mask},
          components_indexes = {}
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
          components_indexes = {{velocity_component, position_component}}
        }, test_system_data)
    end

    it ("updates the associated generational indexes of the components",
    function()
      local test_system_data = system_data.new(
        {velocity_mask}, {position_mask}
      )
      system_data.update(test_system_data, entities_storage)

      assert_test(test_system_data)
    end)

    it ("can be used as method", function ()
      local test_system_data = system_data.new(
        {velocity_mask}, {position_mask}
      )
      test_system_data:update(entities_storage)

      assert_test(test_system_data)
    end)
  end)

  describe("'get_components' function", function()
    local function assert_test
    (e_velocity, e_position, exp_velocity, exp_position, correct_order)
      if correct_order then
        assert.are_same(exp_velocity, e_velocity)
        assert.are_same(exp_position, e_position)
      else
        assert.are_not_same(exp_velocity, e_velocity)
        assert.are_not_same(exp_position, e_position)

        assert.are_same(exp_velocity, e_position)
        assert.are_same(exp_position, e_velocity)
      end
    end

    it("gets the values of the components in the same"
    .. "order as they were passed in the 'new' function",
    function ()
      local test_system_data = system_data.new(
        {velocity_mask}, {position_mask}
      )

      -- this will fail and will returns nil, "invalid index"
      -- because the 'update' was not executed
      local not_ok_components, err_msg = system_data.get_components(
        test_system_data,
        -- must be in the same order as passed in new:
        {velocity_storage, position_storage},
        1
      )

      assert.is_nil(not_ok_components)
      assert.are_same("invalid index", err_msg)

      system_data.update(test_system_data, entities_storage)

      -- this should return {velocity_value, position_value}:
      local ok_components, err = system_data.get_components(
        test_system_data,
        {velocity_storage, position_storage}, -- must be in the right order
        1
      )

      if not ok_components then
        -- luacov: disable
        error(err)
        -- luacov: enable
      else
        local e_velocity, e_position = _unpack(ok_components)

        assert_test(
          e_velocity, e_position, velocity_value, position_value, true
        )
      end

      local wrong_e_velocity, wrong_e_position = _unpack(
        system_data.get_components(
          test_system_data,
          {position_storage, velocity_storage}, -- note: inverted order here
          1
        )
      )

      assert_test(
        wrong_e_velocity, wrong_e_position,
        velocity_value, position_value,
        false
      )
    end)

    it("can be used as a method", function ()
      local test_system_data = system_data.new(
        {velocity_mask}, {position_mask}
      )
      system_data.update(test_system_data, entities_storage)

      local e_velocity, e_position = _unpack(
        test_system_data:get_components(
          {velocity_storage, position_storage}, 1
        )
      )

      assert_test(e_velocity, e_position, velocity_value, position_value,true)
    end)
  end)

  describe("'iterate_components' function", function()
    local function assert_test
    (e_velocity, e_position, exp_velocity, exp_position)
      assert.are_same(exp_velocity, e_velocity)
      assert.are_same(exp_position, e_position)
    end

    it("iterates over the components indexes and uses get_components to "
    .. "returns the components values", function ()
      local test_system_data = system_data.new(
        {velocity_mask}, {position_mask}
      )
      system_data.update(test_system_data, entities_storage)

      -- you can unpack
      for e_velocity, e_position in system_data.iterate_components(
        test_system_data, {velocity_storage, position_storage}, true
      ) do
        assert_test(e_velocity, e_position, velocity_value, position_value,true)
      end

      -- or get as a table (array)
      for components in system_data.iterate_components(
        test_system_data, {velocity_storage, position_storage}, false
      ) do
        local e_velocity, e_position = components[1], components[2]
        assert_test(e_velocity, e_position, velocity_value, position_value,true)
      end
    end)

    it ("can be used as a method", function ()
      local test_system_data = system_data.new(
        {velocity_mask}, {position_mask}
      )
      system_data.update(test_system_data, entities_storage)

      -- you can unpack
      for e_velocity, e_position in test_system_data:iterate_components(
        {velocity_storage, position_storage}, true
      ) do
        assert_test(e_velocity, e_position, velocity_value, position_value,true)
      end

      -- or get as a table (array)
      for components in test_system_data:iterate_components(
        {velocity_storage, position_storage}, false
      ) do
        local e_velocity, e_position = components[1], components[2]
        assert_test(e_velocity, e_position, velocity_value, position_value,true)
      end
    end)
  end)

  describe("is used to make systems", function ()
    local function movement_func(velocity, position)
      position.x = position.x + velocity.x
      position.y = position.y + velocity.y
    end

    -- using iterate components it's the easiest way
    it ("using the 'iterate_components' function", function()
      local function movement_system (
        arg_system_data, arg_velocity_storage, arg_position_storage
      )
        for e_velocity, e_position in arg_system_data:iterate_components(
          {arg_velocity_storage, arg_position_storage}, true
        ) do
          movement_func(e_velocity, e_position)
          assert.are_same({x = -1, y = -1}, e_position)
        end
      end

      local test_system_data = system_data.new(
        {velocity_mask}, {position_mask}
      )
      system_data.update(test_system_data, entities_storage)

      movement_system(test_system_data, velocity_storage, position_storage)
    end)

    -- but you can also do this if you want more control
    it("using the 'get_components' function and iterating directly", function ()
      local function movement_system (
        arg_system_data, arg_velocity_storage, arg_position_storage
      )
        for i = 1, #arg_system_data.components_indexes do
          local ok_components, err_msg = arg_system_data:get_components(
            {arg_velocity_storage, arg_position_storage},
            i
          )

          if ok_components then
            local e_velocity = ok_components[1]
            local e_position = ok_components[2]
            movement_func(e_velocity, e_position)

            -- note:  The 'position' has already been moved
            -- by 'velocity' in the previous test.
            assert.are_same({x = 1, y = 3}, e_position)
          else
            -- luacov: disable
            error(err_msg)
            -- luacov: enable
          end
        end
      end

      local test_system_data = system_data.new(
        {velocity_mask}, {position_mask}
      )
      system_data.update(test_system_data, entities_storage)

      movement_system(test_system_data, velocity_storage, position_storage)
    end)
  end)
end)
