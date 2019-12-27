describe("entity library", function()
  local storage = require "motor.storage"
  local entity = require "motor.entity"
  local bitset_array = require "motor.bitset_array"

  -- component constructors
  local function new_point (x, y)
    return {x = x, y = y}
  end
  local function new_name(n)
    return {name = n}
  end

  local point_storage = storage.new()
  local point1 = point_storage:new_entry(new_point(1, 2))
  local point2 = point_storage:new_entry(new_point(0, 0))
  local point_mask = bitset_array.new(1, {1})

  local name_storage = storage.new()
  local name1 = name_storage:new_entry(new_name("my entity test"))
  local name_mask = bitset_array.new(1, {1}):lshift(1)

  describe("'new' function", function ()
    it("creates a new entity", function ()
      local test_entity = entity.new()
      assert.truthy(test_entity)
    end)
  end)

  describe("'associate' function", function()
    local function assert_associated_entity_data(test_entity, point, name)
      if name then
        assert.are_same({
            mask = bitset_array.bor(point_mask, name_mask),
            associated_components = {point, name},
            associated_storages = {point_mask, name_mask},
            untracked = true
          }, test_entity)
      else
        assert.are_same({
          mask = point_mask,
          associated_components = {point},
          associated_storages = {point_mask},
          untracked = true
        }, test_entity)
      end
    end

    it ("associates the entity with a component and it's storage", function()
      local test_entity = entity.new()
      entity.associate(test_entity, point1, point_mask)
      assert_associated_entity_data(test_entity, point1)
    end)

    it ("can associate multiple components", function ()
      local test_entity = entity.new()
      entity.associate(test_entity, point1, point_mask)
      entity.associate(test_entity, name1, name_mask)
      assert_associated_entity_data(test_entity, point1, name1)
    end)

    it ("can be used as a method", function()
      local test_entity = entity.new()
      test_entity:associate(point1, point_mask)
      assert_associated_entity_data(test_entity, point1)
    end)
  end)

  describe("'disassociate' function", function ()
    local function assert_disassociated_entity_data(test_entity)
      assert.are_same({
        mask = {0},
        associated_components = {},
        associated_storages   = {},
        untracked = true
      }, test_entity)
    end

    it("disassociates the component and storage to the entity", function ()
      local test_entity = entity.new()

      entity.associate(test_entity, point1, point_mask)
      assert.is_true(entity.disassociate(test_entity, point1))
      assert_disassociated_entity_data(test_entity)

      entity.associate(test_entity, point1, point_mask)
      assert.is_true(entity.disassociate(test_entity, point_mask))
      assert_disassociated_entity_data(test_entity)
    end)

    it ("returns true if succeeds; nil, string otherwise", function()
      local test_entity = entity.new()

      local ok, err = entity.disassociate(test_entity, point1)
      assert.is_nil(ok)
      assert.are_same("component index not found", err)
    end)

    it("can be used as a method", function ()
      local test_entity = entity.new()
      entity.associate(test_entity, point1, point_mask)

      assert.is_true(test_entity:disassociate(point1))
      assert_disassociated_entity_data(test_entity)

      entity.associate(test_entity, point1, point_mask)

      assert.is_true(test_entity:disassociate(point_mask))
      assert_disassociated_entity_data(test_entity)
    end)
  end)

  describe("'get_component_index' function", function ()
    it("get the index of an associated component", function ()
      local test_entity = entity.new()
      entity.associate(test_entity, point1, {1})

      do
        local ok_index, err_msg =entity.get_component_index(test_entity, point1)
        assert.are_same(1, ok_index)
        assert.is_nil(err_msg)
      end
      do
        local ok_index, err_msg =entity.get_component_index(test_entity, point2)
        assert.is_nil(ok_index)
        assert.are_same("component index not found", err_msg)
      end
    end)

    it("can be used as a method", function ()
      local test_entity = entity.new()
      entity.associate(test_entity, point1, {1})

      do
        local ok_index, err_msg = test_entity:get_component_index(point1)
        assert.are_same(1, ok_index)
        assert.is_nil(err_msg)
      end
      do
        local ok_index, err_msg = test_entity:get_component_index(point2)
        assert.is_nil(ok_index)
        assert.are_same("component index not found", err_msg)
      end
    end)
  end)

  describe("'get_storage_index' function", function ()
    it("get the index of an associated storage", function ()
      local test_entity = entity.new()
      entity.associate(test_entity, point1, {1})

      do
        local ok_index, err_msg = entity.get_storage_index(test_entity, {1})
        assert.are_same(1, ok_index)
        assert.is_nil(err_msg)
      end
      do
        local ok_index, err_msg = entity.get_storage_index(test_entity, {2})
        assert.is_nil(ok_index)
        assert.are_same("storage index not found", err_msg)
      end
    end)

    it("can be used as a method", function ()
      local test_entity = entity.new()
      entity.associate(test_entity, point1, {1})

      do
        local ok_index, err_msg = test_entity:get_storage_index({1})
        assert.are_same(1, ok_index)
        assert.is_nil(err_msg)
      end
      do
        local ok_index, err_msg = test_entity:get_storage_index({2})
        assert.is_nil(ok_index)
        assert.are_same("storage index not found", err_msg)
      end
    end)
  end)
end)
