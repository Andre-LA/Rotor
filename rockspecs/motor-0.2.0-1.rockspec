package = "motor"
version = "0.2.0-1"

source = {
   url = "git://github.com/Andre-LA/Motor",
   tag = "v0.2.0"
}

description = {
   summary = "Set of libraries for doing ECS in Lua",
   license = "MIT/X11",
}

build = {
   type = "builtin",
   modules = {
      ["entity"]             = "src/entity.lua",
      ["storage"]            = "src/storage.lua",
      ["system_data"]        = "src/system_data.lua",
      ["bitset_array"]       = "src/bitset_array.lua",
      ["generational_index"] = "src/generational_index.lua",

      ["lua5x-operations"]     = "src/lua5x-operations.lua",
      ["lua5x-operations.5_1"] = "src/lua5x-operations/5_1.lua",
      ["lua5x-operations.5_2"] = "src/lua5x-operations/5_2.lua",
      ["lua5x-operations.5_3"] = "src/lua5x-operations/5_3.lua",
   },
   copy_directories = {"doc"},
}

dependencies = {
   "lua >= 5.1, < 5.4"
}
