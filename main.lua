-- example file
local Motor = require ("motor/motor")
local motor = Motor.new(
   { -- components constructors:
       position = function(v) return {x = v.x, y = v.y} end,
       velocity = function(v) return {x = v.x, y = v.y} end,
       mesh     = function(v) return {mesh = love.graphics.newMesh(v.vertices, v.mode, v.usage)} end,
       drawable = function(v) return {drawable = v.drawable} end,
   },
   { -- systems:
      "move", require ("example_systems/move_system"),
      "drawer", require ("example_systems/draw_drawable_system"),
   }
)


local main_world_id;
local entity_id;

function love.load()
   -- require ("mobdebug").start()

   main_world_id = motor:new_world({"move", "drawer"})
   local world_ref = motor:get_world(main_world_id)

   entity_id = motor.new_entity(world_ref)
   local entity_ref = motor.get_entity(world_ref, entity_id)

   motor:set_components_on_entity(world_ref, entity_ref, {
      "position", {x = 5, y = 5},
      "velocity", {x = 1, y = 1},
      "mesh"    , {vertices = {{-50, -50}, {50, -50}, {50, 50}, {-50, 50}}},
   })
   motor:set_components_on_entity(world_ref, entity_ref, {
      "drawable", {drawable = entity_ref.mesh.mesh}
   })
end

function love.update(dt)
   motor:call("update", dt)
end

function love.keypressed(key)
   if key == "delete" then
      local world_ref = motor:get_world(main_world_id)
      motor.destroy_entity(world_ref, entity_id)
   end
end

function love.draw()
   motor:call("draw")
end
