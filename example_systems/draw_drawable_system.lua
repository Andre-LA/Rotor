local draw_drawable_system = {name = "draw_drawable_system"}
draw_drawable_system.__index = draw_drawable_system

function draw_drawable_system.new(_motor, _world)
  local new = {
    motor = _motor,
    entities = {},
    world = _world,
  }
  setmetatable(new, draw_drawable_system)
  return new
end

setmetatable(draw_drawable_system, {__call = function(_, m, w)
  return draw_drawable_system.new(m, w)
end})

function draw_drawable_system.filter (e)
  return e.drawable and e.position
end

function draw_drawable_system:draw ()
  local entities = self.entities
  local e = 1
  while e <= #entities do
    local e_drawable = entities[e].drawable
    local e_position = entities[e].position
    love.graphics.draw(e_drawable.drawable, e_position.x, e_position.y)
    e = e + 1 -- if you destroy an entity,
    -- then it should not add e, because the next entity will be at the current e index
  end
end

return draw_drawable_system
