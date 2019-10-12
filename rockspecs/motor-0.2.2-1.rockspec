package = "motor"
version = "0.2.1-1"

source = {
   url = "git://github.com/Andre-LA/Motor",
   tag = "v0.2.1"
}

description = {
   summary = "Set of libraries for doing ECS in Lua",
   license = "MIT/X11",
}

build = {
   type = "builtin",
   modules = {
      ["motor.entity"]             = "motor/entity.lua",
      ["motor.storage"]            = "motor/storage.lua",
      ["motor.system_data"]        = "motor/system_data.lua",
      ["motor.bitset_array"]       = "motor/bitset_array.lua",
      ["motor.generational_index"] = "motor/generational_index.lua",

      ["motor.lua5x-operations"]     = "motor/lua5x-operations.lua",
      ["motor.lua5x-operations.5_1"] = "motor/lua5x-operations/5_1.lua",
      ["motor.lua5x-operations.5_2"] = "motor/lua5x-operations/5_2.lua",
      ["motor.lua5x-operations.5_3"] = "motor/lua5x-operations/5_3.lua",
   },
   copy_directories = {"doc"},
}

dependencies = {
   "lua >= 5.1, < 5.4"
}
