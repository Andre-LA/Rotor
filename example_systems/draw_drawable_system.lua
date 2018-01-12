local draw_drawable_system = {}
local Draw_Drawable_System = {}
Draw_Drawable_System.__index = Draw_Drawable_System
local _setmetatable = setmetatable

function Draw_Drawable_System.filter (e)
    return e.drawable and e.position
end

function Draw_Drawable_System:draw ()
   local world = self.motor:get_world(self.world_id)
   local entities = self.motor.get_entities(world, self.ids)
   for e=#entities, 1, -1 do
      local e_drawable = entities[e].drawable
      local e_position = entities[e].position
      love.graphics.draw(e_drawable.drawable, e_position.x, e_position.y)
   end
end

function draw_drawable_system.new(_motor, _world)
   local new = {
      motor = _motor,
      ids   = {},
      world_id = _world,
   }
   _setmetatable(new, Draw_Drawable_System)
   return new
end
return draw_drawable_system
