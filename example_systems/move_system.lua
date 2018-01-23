local move_system = {}
local Move_System = {}
Move_System.__index = Move_System

local _setmetatable = setmetatable

function Move_System.filter (e)
  return e.velocity and e.position
end

function Move_System:update()
  local entities = self.entities
  local e = 1
  while e <= #entities do
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
    e = e + 1 -- if you destroy an entity,
    -- then it should not add e, because the next entity will be at the current e index
  end
end

function move_system.new(_motor, _world)
  local new = {
    motor = _motor,
    entities = {},
    world = _world,
  }
  _setmetatable(new, Move_System)
  return new
end

return move_system
