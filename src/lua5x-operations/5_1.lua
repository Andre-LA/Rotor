-- operations using 5.1 features, but needs the 'bit' library,
-- bit is enabled by default in <a href="luajit.org">LuaJIT</a>
-- , but can also be installed with <a href="https://luarocks.org/modules/luarocks/luabitop">luarocks</a>

local _bit = require 'bit'

return {
  -- bit operations
  band   = _bit.band,
  bor    = _bit.bor,
  bxor   = _bit.bxor,
  rshift = _bit.rshift,
  lshift = _bit.lshift,
  bnot   = _bit.bnot,
  unpack = unpack
}
