local render = {}
local Render = {}
Render.__index = Render
local _setmetatable = setmetatable

function Render.filter (_)
    return true
end

function Render:draw()
    local world = self.motor:get_world(self.world_id)
    local entities = self.motor.get_entities(world, self.ids)
    for e=#entities, 1, -1 do
        local e_position = entities[e].position
        love.graphics.rectangle("line", e_position.x, e_position.y, 100, 100)
    end
end

function render.new(_motor, _world)
   local new = {
      world_id = _world,
      ids = {},
      motor = _motor
   }
   _setmetatable(new, Render)
   return new
end

return render
