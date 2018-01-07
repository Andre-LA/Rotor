local systemtest = {}
systemtest.__index = systemtest
local _setmetatable = setmetatable

function systemtest.new(_motor, _world)
    local new = {
        world_id = _world,
        ids = {},
        motor = _motor,
    }
    _setmetatable(new, systemtest)
    return new
end

function systemtest.filter (e)
    return e.velocity and e.position
end

function systemtest.update(self)
    local world = self.motor:get_world(self.world_id)
    local entities = self.motor.get_entities(world, self.ids)
    for e=#entities, 1, -1 do
        local e_position = entities[e].position
        local e_velocity = entities[e].velocity
        e_position.x = e_position.x + e_velocity.x
        e_position.y = e_position.y + e_velocity.y
    end
end

return systemtest
