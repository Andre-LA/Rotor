-- example file
local Motor = require ("motor/motor")
local motor = Motor.new(
  { -- components constructors:
    position = function(v) return {x = v.x, y = v.y} end,
    velocity = function(v) return {x = v.x, y = v.y} end,
    mesh     = function(v) return {value = love.graphics.newMesh(v.vertices, v.mode, v.usage)} end,
    drawable = function(v, e) return {drawable = e[v.drawable].value} end,
  },
  { -- systems (will be executed in the following order):
    require ("example_systems/move_system"),
    require ("example_systems/draw_drawable_system"),
  }
)

local main_world_id;
local entity_id;

function love.load()
  local world_ref;
  main_world_id, world_ref = motor:new_world({"move_system", "draw_drawable_system"})

  local entity_ref;
  entity_id, entity_ref = motor.new_entity(world_ref)

  motor:set_components_on_entity(world_ref, entity_ref, {
    "position", {x = 150, y = 250},
    "velocity", {
      x = 10,
      y = 10
    },
    "mesh", {
      vertices = {
        {-50, -50}, { 50, -50},
        { 50,  50}, {-50,  50}
      }
    },
    "drawable", {
      drawable = "mesh"
    }
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
