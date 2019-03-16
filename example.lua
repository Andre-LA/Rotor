--require 'mobdebug'.on()

-- minimal example:-- 3 components: position, velocity and name
-- 2 systems: translator system and "who's on the right most?"
-- creates 3 entities, with these 2 components, but each one with different data
-- run these systems 300x
-- disassociate velocity component of all entities

local positions_state_data_bit_id  = 0 -- :bitid
local velocities_state_data_bit_id = 0 -- :bitid
local names_state_data_bit_id      = 0 -- :bitid

local USAR_TITAN = true

-- requires
local motor    = require ('motor' .. (USAR_TITAN and '_titan' or ''))
local states   = motor.states
local entities = motor.entities
local storages = motor.storages
local systems  = motor.systems

-- declare position, rotation and name component constructors
local Position = {
  new = function (_x, _y)
    return {
      x = _x,
      y = _y
    }
  end
}

local Velocity = {
  new = function (_v)
    return { v = _v }
  end
}

local Name = {
  new = function (_name)
    return { name  = _name}
  end
}

local TranslatorSystem = {
  new = function(_system_data)
    return {
      system_data = _system_data,

      run = function(self, state_datas)
        print ("\tTranslator system begin")

        local components = self.system_data.components_ids_to_iterate

        local vel_storage = state_datas[velocities_state_data_bit_id]
        local pos_storage = state_datas[positions_state_data_bit_id]

        for i = 1, #components do

          local vel_i = vel_storage:get_entry(components[i][1]).content
          local pos_i = pos_storage:get_entry(components[i][2]).content

          print ("\t\tupdating position, x = x + v -> " .. pos_i.x .. " = " .. pos_i.x .. " + " .. vel_i.v)

          pos_i.x = pos_i.x + vel_i.v

        end

        print ("\tTranslator system end")
      end
    }
  end
}

local WhoIsInTheRightMostStateData = {
  new = function()
    return {
      pos_id  = 0, -- : storages.Id
      name_id = 0 -- : storages.Id
    }
  end
}

local WhoIsInTheRightMostSystem = {
  new = function(_system_data)
    return {
      system_data = _system_data,

      run = function (self, state_datas)
        print("\tWho is on the right most system begin")

        local simple_state_datas = self.system_data.simple_state_data_needs
        local components = self.system_data.components_ids_to_iterate

        local pos_storage = state_datas[positions_state_data_bit_id]
        local rightmost_data = state_datas[simple_state_datas[1]]

        local rightmost_pos = -999999999
        local rightmost_idx = 0

        for i = 1, #components do

          local pos_i = pos_storage:get_entry(components[i][1]).content


          if pos_i.x  > rightmost_pos then
            print("\t\tupdating rightmost entity information: x = " .. pos_i.x)
            rightmost_pos = pos_i.x
            rightmost_idx = i
          end
        end


        rightmost_data.pos_id  = components[rightmost_idx][1]
        rightmost_data.name_id = components[rightmost_idx][2]

        local names_storage = state_datas[names_state_data_bit_id]

        local name_rm = names_storage:get_entry(components[rightmost_idx][2]).content

        print("\t\tThe rightmost entity for now is: " .. name_rm.name)

        print("\tWho is on the right most system end")
      end
    }
  end
}

local MainState = {
  new = function(_state)
    return {
      state = _state,

      init_systems = function (self, translator_sys, who_in_right_sys)
        translator_sys.system_data:update_components_ids_to_iterate(entities_storage.entries)
        who_in_right_sys.system_data:update_components_ids_to_iterate(entities_storage.entries)
      end,

      run = function (self, translator_sys, who_in_right_sys)
        translator_sys:run(self.state.state_data)
        who_in_right_sys:run(self.state.state_data)
      end
    }
  end
}

local function main()
  print("start")

  local main_state = MainState.new(states.new_state())
  entities_storage = main_state.state.state_data[main_state.state.entities_state_data_bit_id]

  positions_state_data_bit_id  = main_state.state:add_state_data(storages.new_storage())
  velocities_state_data_bit_id = main_state.state:add_state_data(storages.new_storage())
  names_state_data_bit_id      = main_state.state:add_state_data(storages.new_storage())

  local rightmost_components_bit_id = main_state.state:add_state_data(
    WhoIsInTheRightMostStateData.new(
      storages.Id.new(0,0),
      storages.Id.new(0,0)
    )
  )

  local translator_sys = TranslatorSystem.new(
    systems.init_system_data (
      {
        {},
        {}
      },
      {
        {velocities_state_data_bit_id},
        {positions_state_data_bit_id}
      }
    )
  )

  local who_in_right_sys = WhoIsInTheRightMostSystem.new(
    systems.init_system_data (
      {
        {},
        {rightmost_components_bit_id}
      },
      {
        {positions_state_data_bit_id, names_state_data_bit_id},
        {}
      }
    )
  )

  local positions_storage = main_state.state.state_data[positions_state_data_bit_id]
  local names_storage     = main_state.state.state_data[names_state_data_bit_id]

  for i=1, 3 do
    local velocities_storage = main_state.state.state_data[velocities_state_data_bit_id]

    local new_entity_id = entities_storage:new_entry(entities.new_entity())

    local new_name_id = names_storage:new_entry(Name.new("entity #" .. i))

    local new_position_id = positions_storage:new_entry(Position.new(10 - i*13, 0))

    local new_velocity_id = velocities_storage:new_entry(Velocity.new(5 + i))

    local entry_of_new_entity = entities_storage:get_entry(new_entity_id)
    entry_of_new_entity = entry_of_new_entity.content

    entry_of_new_entity:associate_component(
      new_name_id,
      names_state_data_bit_id
    )

    entry_of_new_entity:associate_component(
      new_position_id,
      positions_state_data_bit_id
    )

    entry_of_new_entity:associate_component(
      new_velocity_id,
      velocities_state_data_bit_id
    )
  end


  main_state:init_systems(translator_sys, who_in_right_sys)

  for i = 1, 4 do
    main_state:run(translator_sys, who_in_right_sys)
  end

  for i=1, #entities_storage.entries do
    local entity = entities_storage:get_entry(entities_storage.entries[i].id).content

    entity:disassociate_component(
      entity.associated_components_entries_ids[entity:find_associated_bit_id(velocities_state_data_bit_id)], -- associated velocity id
      velocities_state_data_bit_id -- velocities state data bit id
    )
  end

  local rightmost_data = main_state.state.state_data[rightmost_components_bit_id]

  local position_id = rightmost_data.pos_id
  local name_id = rightmost_data.name_id

  local position = positions_storage:get_entry(position_id).content

  local name = names_storage:get_entry(name_id).content

  print("end")
end

main()
