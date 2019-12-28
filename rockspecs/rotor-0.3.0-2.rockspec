package = "rotor"
version = "0.3.0-2"
source = {
   url = "git://github.com/Andre-LA/Rotor",
   tag = "v0.3.0"
}
description = {
   summary = "Set of libraries for doing ECS in Lua",
   license = "MIT/X11"
}
dependencies = {
   "lua >= 5.1, < 5.4"
}
build = {
   type = "builtin",
   modules = {
      ["rotor.bitset_array"] = "rotor/bitset_array.lua",
      ["rotor.entity"] = "rotor/entity.lua",
      ["rotor.generational_index"] = "rotor/generational_index.lua",
      ["rotor.storage"] = "rotor/storage.lua",
      ["rotor.system_data"] = "rotor/system_data.lua",

      ["rotor.lua5x-operations"] = "rotor/lua5x-operations.lua",
      ["rotor.lua5x-operations.5_1"] = "rotor/lua5x-operations/5_1.lua",
      ["rotor.lua5x-operations.5_2"] = "rotor/lua5x-operations/5_2.lua",
      ["rotor.lua5x-operations.5_3"] = "rotor/lua5x-operations/5_3.lua",
   }
}
