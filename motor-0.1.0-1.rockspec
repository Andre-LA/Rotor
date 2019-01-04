package = "motor"
version = "0.1.0-1"
source = {
   url = "git://github.com/Andre-LA/Motor",
   tag = "v0.1.0"
}
description = {
   summary = "ECS library for Lua, inspired from SPECS",
   license = "MIT/X11",

}
build = {
   type = "builtin",
   modules = {
      bit_ids  = "motor/bit_ids.lua",
      states   = "motor/states.lua",
      entities = "motor/entities.lua",
      storages = "motor/storages.lua",
      systems  = "motor/systems.lua",
      operations = "motor/operations/init.lua",
      ["operations.lua51_operations"] = "motor/operations/lua51_operations.lua",
      ["operations.lua53_operations"] = "motor/operations/lua53_operations.lua",
   },
   copy_directories = {"docs"},
}
dependencies = {
   "lua >= 5.1, <= 5.3, ~= 5.2"
}
