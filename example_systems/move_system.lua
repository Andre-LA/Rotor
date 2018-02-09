local move_system = {name = "move_system"}
move_system.__index = move_system

function move_system.new(_motor, _world)
  local new = {
    motor = _motor,
    entities = {},
    world = _world,
  }
  setmetatable(new, move_system)
  return new
end

setmetatable(move_system, {__call = function(_, m, w)
  return move_system.new(m, w)
end})

function move_system.filter (e)
  return e.velocity and e.position
end

function move_system:update(dt)
  local entities = self.entities
  local e = 1
  while e <= #entities do
    local e_position = entities[e].position
    local e_velocity = entities[e].velocity
    -- horizontal movement    
    if love.keyboard.isDown('d') then
      e_position.x = e_position.x + e_velocity.x * dt
    end
    if love.keyboard.isDown('a') then
      e_position.x = e_position.x - e_velocity.x * dt
    end
    -- vertical movement
    if love.keyboard.isDown('s') then
      e_position.y = e_position.y + e_velocity.y * dt
    end
    if love.keyboard.isDown('w') then
      e_position.y = e_position.y - e_velocity.y * dt
    end
    e = e + 1 -- if you destroy an entity,
    -- then it should not add e, because the next entity will be at the current e index
  end
end

return move_system
