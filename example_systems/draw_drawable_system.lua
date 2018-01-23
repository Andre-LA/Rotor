local draw_drawable_system = {}
local Draw_Drawable_System = {}
Draw_Drawable_System.__index = Draw_Drawable_System
local _setmetatable = setmetatable

function Draw_Drawable_System.filter (e)
  return e.drawable and e.position
end

function Draw_Drawable_System:draw ()
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

function draw_drawable_system.new(_motor, _world)
  local new = {
    motor = _motor,
    entities = {},
    world = _world,
  }
  _setmetatable(new, Draw_Drawable_System)
  return new
end
return draw_drawable_system
