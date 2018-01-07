local _unpack = table.unpack or unpack

local Motor = require 'motor'
local motor = Motor.new(
-- components constructors:
{
    position = function(v) return {x = v.x, y = v.y} end,
    velocity = function(v) return {x = v.x, y = v.y} end
},
-- systems:
{
    moveSystem = require ("systemtest"),
    renderSystem = require ("render")
}
)

function love.load(arg)
    -- require ("mobdebug").start()

    local main_world_id = motor:new_world({'moveSystem', 'renderSystem'})
    local entity_id = motor:new_entities(main_world_id, 1)[1]

    motor:set_components_on_entity(main_world_id, entity_id, {
        "position", {x = 5, y = 5},
        "velocity", {x = 1, y = 0},
    })
end

function love.update(dt)
    motor:call('update', dt)
    print()
end

function love.draw()
    motor:call('draw')
end
