package = "motor"
version = "0.1.0-2"
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
      ["motor.bit_ids"]    = "motor/bit_ids.lua" ,
      ["motor.states"]     = "motor/states.lua"  ,
      ["motor.entities"]   = "motor/entities.lua",
      ["motor.storages"]   = "motor/storages.lua",
      ["motor.systems"]    = "motor/systems.lua" ,
      ["motor.operations"] = "motor/operations/init.lua",
      ["motor.operations.lua51_operations"] = "motor/operations/lua51_operations.lua",
      ["motor.operations.lua53_operations"] = "motor/operations/lua53_operations.lua",
   },
   copy_directories = {"docs"},
}
dependencies = {
   "lua >= 5.1, <= 5.3, ~= 5.2"
}
