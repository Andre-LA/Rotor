describe("storage library", function ()
  local storage = require ("rotor.storage")
  local generational_index = require ("rotor.generational_index")

  describe("'new' function", function ()
    it("creates a new storage", function()
      local test_storage = storage.new()
      assert.truthy(test_storage)
    end)
  end)

  describe("'new_entry' function", function ()
    local test_storage = storage.new()

    it ("create an entry in the storage that stores a value", function()
      storage.new_entry(test_storage, "some value")

      -- never do this in real code:
      assert.are_equal(test_storage.entries[1], "some value")
    end)

    it ("can be used as a method", function ()
      test_storage:new_entry("other value")

      -- never do this in real code:
      assert.are_equal(test_storage.entries[2], "other value")
      assert.are_not_equal(test_storage.entries[1], "other value")
      assert.are_equal(test_storage.entries[1], "some value")
    end)
  end)

  describe("'get_entry' function", function()
    local test_storage = storage.new()

    local vl_id_1 = storage.new_entry(test_storage, "value #1")
    local vl_id_2 = storage.new_entry(test_storage, "value #2")
    local vl_id_3 = storage.new_entry(test_storage, "value #3")

    it("try to get the value of an entry by it's ID", function ()
      -- possible, but not a good way to get an entry:
      local vl_1 = storage.get_entry(test_storage, vl_id_1)
      local vl_2 = storage.get_entry(test_storage, vl_id_2)
      local vl_3 = storage.get_entry(test_storage, vl_id_3)

      assert.are_equal(vl_1, "value #1")
      assert.are_equal(vl_2, "value #2")
      assert.are_equal(vl_3, "value #3")

      -- you should get an entry in this way:
      local ok_vl_3, err_msg = storage.get_entry(test_storage, vl_id_3)

      if ok_vl_3 then
        assert.are_equal(ok_vl_3, "value #3")
      else
        -- luacov: disable
        error(err_msg)
        -- luacov: enable
      end
    end)

    it("fail when try to get a value of an invalid ID", function ()
      local fake_id = generational_index.new(4, 0)
      local inexistent_vl_4, err_msg = storage.get_entry(test_storage, fake_id)
      assert.is_nil(inexistent_vl_4)
      assert.are_equal(err_msg, "entry not found")
    end)

    it("can be used as a method", function ()
      local ok_vl_3, err_msg = test_storage:get_entry(vl_id_3)

      if ok_vl_3 then
        assert.are_equal(ok_vl_3, "value #3")
      else
        -- luacov: disable
        assert.is_nil(ok_vl_3)
        assert.are_equal(err_msg, "entry not found")
        -- luacov: enable
      end
    end)
  end)

  describe("'remove_entry' function", function ()
    local test_storage;

    local vl_id_2, vl_id_3, vl_id_4;

    before_each(function()
      test_storage = storage.new()
      storage.new_entry(test_storage, "value #1")
       vl_id_2 = storage.new_entry(test_storage, "value #2")
       vl_id_3 = storage.new_entry(test_storage, "value #3")
       vl_id_4 = storage.new_entry(test_storage, "value #4")
    end)

    it("removes an entry by it's ID", function ()
      assert.is_true(storage.remove_entry(test_storage, vl_id_2))
      assert.is_nil(storage.get_entry(test_storage, vl_id_2))
    end)

    it ("returns if the entry was found by it's ID", function ()
      assert.is_true(storage.remove_entry(test_storage, vl_id_2))

      local ok, err = storage.remove_entry(test_storage, vl_id_2)

      assert.is_nil(ok)
      assert.are_equal(err, "entry not found") -- because it was deleted before
    end)

    it ("can be used as a method", function ()
      assert.is_true(test_storage:remove_entry(vl_id_3))
      assert.is_nil(test_storage:get_entry(vl_id_3))
    end)

    it ("updates 'len' when removes the last entry", function()
      assert.are_same(4, test_storage.len)
      assert.is_true(storage.remove_entry(test_storage, vl_id_4))
      assert.are_same(3, test_storage.len)
    end)
  end)

  describe("'iterate_entries' function", function ()
    local test_storage = storage.new()

    storage.new_entry(test_storage, "value #1")
    local vl_id_2 = storage.new_entry(test_storage, "value #2")
    storage.new_entry(test_storage, "value #3")
    storage.remove_entry(test_storage, vl_id_2)

    it("iterates valid entries", function ()
      local entries = {}
      for entry in storage.iterate_entries(test_storage) do
        -- iterate_entries only iterates on valid entries
        -- so, it's safe, no need of ok_entry, err_msg thing
        table.insert(entries, entry)
      end
      assert.are_same({"value #1", "value #3"}, entries)
    end)

    it ("can be used as a method", function()
      local entries = {}
      for entry in test_storage:iterate_entries() do
        table.insert(entries, entry)
      end
      assert.are_same({"value #1", "value #3"}, entries)
    end)
  end)

  it("Reuses space when have free slot", function ()
    local test_storage = storage.new()

    test_storage:new_entry("value #1")
    local vl_id_2 = test_storage:new_entry("value #2")
    test_storage:new_entry("value #3")

    assert.is_true(test_storage:remove_entry(vl_id_2))

    assert.is_nil(test_storage:get_entry(vl_id_2))
    assert.is_nil(test_storage.entries[2])

    local vl_id_4 = test_storage:new_entry("value #4")

    assert.are_equal(test_storage.entries[2], "value #4")
    assert.is_nil(test_storage:get_entry(vl_id_2))
    assert.are_equal(test_storage:get_entry(vl_id_4), "value #4")
  end)
end)
