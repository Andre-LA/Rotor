local Motor = require ("motor/motor")
local motor = Motor.new(
-- components constructors:
{
    position = function(v) return {x = v.x, y = v.y} end,
    velocity = function(v) return {x = v.x, y = v.y} end
},
-- systems:
{
    moveSystem = require ("test/systemtest"),
    renderSystem = require ("test/render")
}
)

local main_world_id;
local entity_id;

function love.load()
    -- require ("mobdebug").start()

    main_world_id = motor:new_world({"moveSystem", "renderSystem"})
    local world_ref = motor:get_world(main_world_id)

    entity_id = motor.new_entities(world_ref, 1)[1]
    local entity_ref = motor.get_entity(world_ref, entity_id)

    motor:set_components_on_entity(world_ref, entity_ref, {
        "position", {x = 5, y = 5},
        "velocity", {x = 1, y = 0},
    })
end

function love.update(dt)
    motor:call("update", dt)
end

function love.keypressed(key)
   if key == "d" then
      local world_ref = motor:get_world(main_world_id)
      motor.destroy_entity(world_ref, entity_id)
   end
end

function love.draw()
    motor:call("draw")
end
