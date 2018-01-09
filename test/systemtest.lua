local systemtest = {}
local SystemTest = {}
SystemTest.__index = SystemTest
local _setmetatable = setmetatable

function SystemTest.filter (e)
    return e.velocity and e.position
end

function SystemTest:update()
    local world = self.motor:get_world(self.world_id)
    local entities = self.motor.get_entities(world, self.ids)
    for e=#entities, 1, -1 do
        local e_position = entities[e].position
        local e_velocity = entities[e].velocity
        e_position.x = e_position.x + e_velocity.x
        e_position.y = e_position.y + e_velocity.y
    end
end

function systemtest.new(_motor, _world)
   local new = {
      world_id = _world,
      ids = {},
      motor = _motor,
   }
   _setmetatable(new, SystemTest)
   return new
end

return systemtest
