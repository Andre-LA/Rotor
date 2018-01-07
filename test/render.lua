local render = {}
render.__index = render
local _setmetatable = setmetatable

function render.new(_motor, _world)
    local new = {
        world_id = _world,
        ids = {},
        motor = _motor
    }
    _setmetatable(new, render)
    return new
end

function render.filter (_)
    return true
end

function render.draw(self)
    local world = self.motor:get_world(self.world_id)
    local entities = self.motor.get_entities(world, self.ids)
    for e=#entities, 1, -1 do
        local e_position = entities[e].position
        love.graphics.rectangle('line', e_position.x, e_position.y, 100, 100)
    end
end

return render
