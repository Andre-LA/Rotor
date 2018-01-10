local move_system = {}
local Move_System = {}
Move_System.__index = Move_System
local _setmetatable = setmetatable

function Move_System.filter (e)
   return e.velocity and e.position
end

function Move_System:update()
   local world = self.motor:get_world(self.world_id)
   local entities = self.motor.get_entities(world, self.ids)
   for e=#entities, 1, -1 do
      local e_position = entities[e].position
      local e_velocity = entities[e].velocity
      -- horizontal movement
      if love.keyboard.isDown('d') then
         e_position.x = e_position.x + e_velocity.x
      end
      if love.keyboard.isDown('a') then
         e_position.x = e_position.x - e_velocity.x
      end
      -- vertical movement
      if love.keyboard.isDown('s') then
         e_position.y = e_position.y + e_velocity.y
      end
      if love.keyboard.isDown('w') then
         e_position.y = e_position.y - e_velocity.y
      end
   end
end

function move_system.new(_motor, _world)
   local new = {
      motor = _motor,
      ids   = {},
      world_id = _world,
   }
   _setmetatable(new, Move_System)
   return new
end

return move_system
