describe("#bitset_array library", function()
  local bitset_array = require 'motor.bitset_array'

  describe("bitset array data", function ()
    it(
      "the data of a bitset array is a table of n (integer) numbers",
      function ()
        assert.are.same(bitset_array.new(), {0})
        assert.are.same(bitset_array.new(2), {0, 0})
        assert.are.same(bitset_array.new(3), {0, 0, 0})

        local mtype = math.type
        if mtype then
          local bitset = bitset_array.new(3)
          assert.are.same(
            mtype(bitset[1]),
            mtype(bitset[2]),
            mtype(bitset[3]),
            'integer'
          )
        end
      end
    )
  end)

  describe("'copy' function", function ()
    local bitset = bitset_array.new(3)
    local bitset_copy = bitset_array.copy(bitset)

    it("creates a new table", function ()
      assert.are_not.equal(bitset, bitset_copy)
    end)

    it("have the same values", function ()
      assert.are.same(bitset, bitset_copy)

      local another_bitset = bitset_array.new(2)
      another_bitset[2] = 0x2

      bitset_copy = bitset_array.copy(another_bitset)

      assert.are.same(another_bitset, bitset_copy, {0, 0x2})
    end)

    it("can be used as a method", function ()
      local _bitset_copy = bitset:copy()
      local _another_bitset_copy = _bitset_copy:copy()
      assert.are.same(bitset, _bitset_copy, _another_bitset_copy)
    end)
  end)

  describe("'equals' function", function ()
    it("returns true if the bitset arrays have same values", function ()
      local bitset = bitset_array.new(3)
      local equals_bitset = bitset:copy()
      local different_bitset = bitset_array.new(2)

      assert.are.same(bitset, equals_bitset)
      assert.are_not.same(bitset, different_bitset)

      assert.is_true(bitset_array.equals(bitset, equals_bitset))
      assert.is_false(bitset_array.equals(bitset, different_bitset))
    end)

    it("can be used as a method", function ()
      local bitset = bitset_array.new(3)
      local equals_bitset = bitset:copy()
      local different_bitset = bitset_array.new(2)

      assert.are.same(bitset, equals_bitset)
      assert.are_not.same(bitset, different_bitset)

      assert.is_true(bitset:equals(equals_bitset))
      assert.is_false(bitset:equals(different_bitset))
    end)
  end)

  describe('bitwise operation', function ()
    local bitset = bitset_array.new(3)
    local another_bitset = bitset_array.new(2)
    local expected_result = bitset_array.new(3)

    bitset[1] = 0x1   -- 0000 0000 0001
    bitset[2] = 0x32  -- 0000 0011 0010
    bitset[3] = 0xa43 -- 1010 0100 0011

    another_bitset[1] = 0x11  -- 0000 0001 0001
    another_bitset[2] = 0xb78 -- 1011 0111 1000

    local bin = function(s)
      return tonumber(s, 2)
    end

    local LEFTMOSTBIT = 1
    while LEFTMOSTBIT > 0 do
      LEFTMOSTBIT = LEFTMOSTBIT << 1
    end

    local function run_func_with_bitset_array(op_name, other_value)
      local bitset_before = bitset_array.copy(bitset)
      local another_bitset_before = bitset_array.copy(other_value)
      local result = bitset_array[op_name](bitset, other_value)
      return result, bitset_before, another_bitset_before
    end

    local function run_func_with_value(op_name, other_value)
      local bitset_before = bitset_array.copy(bitset)
      local result = bitset_array[op_name](bitset, other_value)
      return result, bitset_before
    end

    local function run_method_with_bitset_array(op_name, other_value)
      local bitset_before = bitset_array.copy(bitset)
      local another_bitset_before = bitset_array.copy(other_value)
      local result = bitset[op_name](bitset, other_value)
      return result, bitset_before, another_bitset_before
    end

    local function run_method_with_value(op_name, other_value)
      local bitset_before = bitset_array.copy(bitset)
      local result = bitset[op_name](bitset, other_value)
      return result, bitset_before
    end

    local function test_bitwise_func(op_name, other_value, other_is_bitset)
      local r1, r2, r3 =  (
        other_is_bitset
          and run_func_with_bitset_array
          or run_func_with_value
        ) (op_name, other_value)
      return r1, r2, r3
    end

    local function test_bitwise_method(op_name, other_value, other_is_bitset)
      local r1, r2, r3 =  (
        other_is_bitset
          and run_method_with_bitset_array
          or run_method_with_value
        ) (op_name, other_value)
      return r1, r2, r3
    end

    local function test_func_and_method(op_name, other_value, other_is_bitset)
      local result, bitset_before, another_bitset_before =
        test_bitwise_func(op_name, other_value, other_is_bitset)

      it("returns a new bit array with the result", function ()
        assert.are_not.equals(bitset, another_bitset, result)
        assert.are.same(expected_result, result)
      end)

      it("Don't change original values", function ()
        assert.are.same(bitset, bitset_before)
        if other_is_bitset then
          assert.are.same(another_bitset, another_bitset_before)
        end
      end)

      result, bitset_before, another_bitset_before =
        test_bitwise_method(op_name, other_value, other_is_bitset)

      it("can be used as a method", function ()
        assert.are_not.equals(bitset, other_value, result)
        assert.are.same(expected_result, result)
      end)
    end

    describe("'band' function", function ()
      expected_result[1] = bitset[1] & another_bitset[1]
      expected_result[2] = bitset[2] & another_bitset[2]
      expected_result[3] = bitset[3] & 1

      test_func_and_method('band', another_bitset, true)
    end)

    describe("'bor' function", function ()
      expected_result[1] = bitset[1] | another_bitset[1]
      expected_result[2] = bitset[2] | another_bitset[2]
      expected_result[3] = bitset[3] | 0

      test_func_and_method('bor', another_bitset, true)
    end)

    describe("'bxor' function", function ()
      expected_result[1] = bitset[1] ~ another_bitset[1]
      expected_result[2] = bitset[2] ~ another_bitset[2]
      expected_result[3] = bitset[3] ~ 0

      test_func_and_method('bxor', another_bitset, true)
    end)

    describe("'lshift' function", function ()
      -- bitset[1]:
      -- 1111 0000 [..] 0000 0000 0000 0001
      bitset[1] = 0x1
        | LEFTMOSTBIT
        | LEFTMOSTBIT >> 1
        | LEFTMOSTBIT >> 2
        | LEFTMOSTBIT >> 3

      -- bitset[2]:
      -- 1110 0000 [..] 0000 0000 0011 0010
      bitset[2] = 0x32
        | LEFTMOSTBIT
        | LEFTMOSTBIT >> 1
        | LEFTMOSTBIT >> 2

      -- bitset[3]:
      -- 0000 0000 0000 0000 1010 0100 0011

      describe("can shift", function()
        -- expected result for 1 step
        -- 1110 0000 [..] 0000 0000 0000 0010
        -- 1100 0000 [..] 0000 0000 0110 0101
        -- 0000 0000 [..] 0001 0100 1000 0111
        describe("1 step", function()
          expected_result[1] =
            0x2 | LEFTMOSTBIT | LEFTMOSTBIT >> 1 | LEFTMOSTBIT >> 2
          expected_result[2] = bin"1100101" | LEFTMOSTBIT | LEFTMOSTBIT >> 1
          expected_result[3] = bin"1010010000111"


          test_func_and_method('lshift', 1)
        end)

        -- expected result for 2 steps
        -- 1100 0000 [..] 0000 0000 0000 0100
        -- 1000 0000 [..] 0000 0000 1100 1011
        -- 0000 0000 [..] 0010 1001 0000 1111
        describe("2 steps", function()
          expected_result[1] = bin"100" | LEFTMOSTBIT | LEFTMOSTBIT >> 1
          expected_result[2] = bin"11001011" | LEFTMOSTBIT
          expected_result[3] = bin"10100100001111"

          test_func_and_method('lshift', 2)
        end)

        -- expected result for 3 steps
        -- 1000 0000 [..] 0000 0000 0000 1000
        -- 0000 0000 [..] 0000 0001 1001 0111
        -- 0000 0000 [..] 0101 0010 0001 1111
        describe("3 steps", function()
          expected_result[1] = bin"1000" | LEFTMOSTBIT
          expected_result[2] = bin"110010111"
          expected_result[3] = bin"101001000011111"

          test_func_and_method('lshift', 3)
        end)

        -- expected result for 4 steps
        -- 0000 0000 [..] 0000 0000 0001 0000
        -- 0000 0000 [..] 0000 0011 0010 1111
        -- 0000 0000 [..] 1010 0100 0011 1110
        describe("4 steps", function()
           expected_result[1] = bin"10000"
           expected_result[2] = bin"1100101111"
           expected_result[3] = bin"1010010000111110"

          test_func_and_method('lshift', 4)
        end)
      end)
    end)

    describe("'rshift' function", function ()
      -- bitset[1]:
      -- 1000 0000 [..] 0000 0000 0000 0001
      bitset[1] = 0x1 | LEFTMOSTBIT

      -- bitset[2]:
      -- 1000 0000 [..] 0000 0000 0011 0010
      bitset[2] = 0x32 | LEFTMOSTBIT

      -- bitset[3]:
      -- 0000 0000 0000 0000 1010 0100 0011

      describe("can shift", function()
        -- expected result for 1 step
        -- 0100 0000 [..] 0000 0000 0000 0000
        -- 1100 0000 [..] 0000 0000 0001 1001
        -- 0000 0000 0000 0000 0101 0010 0001
        describe("1 step", function()
          expected_result[1] = 0 | LEFTMOSTBIT >> 1
          expected_result[2] = bin"11001" | LEFTMOSTBIT | LEFTMOSTBIT >> 1
          expected_result[3] = bin"10100100001"

          test_func_and_method('rshift', 1)
        end)

        -- expected result for 2 steps
        -- 1010 0000 [..] 0000 0000 0000 0000
        -- 1110 0000 [..] 0000 0000 0000 1100
        -- 0000 0000 0000 0000 0010 1001 0000
        describe("2 steps", function()
          expected_result[1] = 0 | LEFTMOSTBIT | LEFTMOSTBIT >> 2
          expected_result[2] =
            bin"1100" | LEFTMOSTBIT | LEFTMOSTBIT >> 1 | LEFTMOSTBIT >> 2
          expected_result[3] = bin"1010010000"

          test_func_and_method('rshift', 2)
        end)

        -- expected result for 3 steps
        -- 0101 0000 [..] 0000 0000 0000 0000
        -- 0111 0000 [..] 0000 0000 0000 0110
        -- 0000 0000 0000 0000 0001 0100 1000
        describe("3 steps", function()
          expected_result[1] = 0 | LEFTMOSTBIT >> 1 | LEFTMOSTBIT >> 3
          expected_result[2] =
            bin"110" | LEFTMOSTBIT >> 1 | LEFTMOSTBIT >> 2 | LEFTMOSTBIT >> 3
          expected_result[3] = bin"101001000"

          test_func_and_method('rshift', 3)
        end)

        -- expected result for 4 steps
        -- 0010 1000 [..] 0000 0000 0000 0000
        -- 0011 1000 [..] 0000 0000 0000 0011
        -- 0000 0000 0000 0000 0000 1010 0100
        describe("4 steps", function()
          expected_result[1] = 0 | LEFTMOSTBIT >> 2 | LEFTMOSTBIT >> 4
          expected_result[2] =
            bin"11" | LEFTMOSTBIT >> 2 | LEFTMOSTBIT >> 3| LEFTMOSTBIT >> 4
          expected_result[3] = bin"10100100"

          test_func_and_method('rshift', 4)
        end)
      end)
    end)

    describe("'bnot' function", function ()
      expected_result[1] = ~bitset[1]
      expected_result[2] = ~bitset[2]
      expected_result[3] = ~bitset[3]

      test_func_and_method('bnot')
    end)
  end)
end)
