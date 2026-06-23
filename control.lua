function OffsetPosition(p1, p2)
    local p1x = p1.x or p1[1]
    local p1y = p1.y or p1[2]
    local p2x = p2.x or p2[1]
    local p2y = p2.y or p2[2]
    return {x=p1x+p2x, y=p1y+p2y}
end


-- Setup tables and stuff for new/existing saves ----
script.on_init(function()
	storage.VacuumHatches_standalone = {}
	storage.OrientationUnitComponents = {}
	storage.OrientationUnitComponents[0] = {x = 0, y = -1, name = "up"}
	storage.OrientationUnitComponents[0.25] = {x = 1, y = 0, name = "right"}
	storage.OrientationUnitComponents[0.5] = {x = 0, y = 1, name = "down"}
	storage.OrientationUnitComponents[0.75] = {x = -1, y = 0, name = "left"}
	storage.OrientationUnitComponents[1] = {x = 0, y = -1, name = "up"}
end
)

-- game version changes, prototypes change, startup mod settings change, adding or removing mods, mod version changes
script.on_configuration_changed(function()
	if (storage.VacuumHatches_standalone == nil) then
		storage.VacuumHatches_standalone = {}
	end
	storage.OrientationUnitComponents = {}
	storage.OrientationUnitComponents[0] = {x = 0, y = -1, name = "up"}
	storage.OrientationUnitComponents[0.25] = {x = 1, y = 0, name = "right"}
	storage.OrientationUnitComponents[0.5] = {x = 0, y = 1, name = "down"}
	storage.OrientationUnitComponents[0.75] = {x = -1, y = 0, name = "left"}
	storage.OrientationUnitComponents[1] = {x = 0, y = -1, name = "up"}
end
)

-- On Built/Copy/Stuff

---- adds new thrower inserters to the list of throwers to check.
---- Make player launchers (reskinned inserters) to be inoperable
---- and inactive ----
script.on_event(
	{
		defines.events.on_built_entity, --| built by hand ----
		defines.events.on_robot_built_entity, --| built by robot ----
		defines.events.script_raised_built, --| built by script ----
		defines.events.on_entity_cloned, -- | cloned by script ----
		defines.events.script_raised_revive, -- | ghost revived by script
		defines.events.on_post_entity_died, -- | ghost created when something dies
		defines.events.on_space_platform_built_entity -- | built by space platform
	},
	function(event)
	local entity = event.created_entity or event.entity or event.destination or {name="ghost"}

	if (entity.name == "RTVacuumHatch_standalone") then
		local id = entity.unit_number

		storage.VacuumHatches_standalone[id] = {
			entity = entity,
			output = nil
		}

		local properties = storage.VacuumHatches_standalone[id]
		-- succ animation
		local succc = rendering.draw_animation
		{
			animation = "VacuumHatchSucc_standalone",
			orientation = entity.orientation,
			surface = entity.surface,
			target = {entity=entity, offset={3*storage.OrientationUnitComponents[entity.orientation].x, 3*storage.OrientationUnitComponents[entity.orientation].y}},
			y_scale = 1.1,
			animation_offset = math.random(100),
			render_layer = "above-inserters"
			--animation_speed = 0.5,
		}
		properties.ParticleAnimation = succc
		-- output entity if any
		properties.output = entity.surface.find_entities_filtered
		({
			collision_mask = "object",
			position = OffsetPosition(entity.position, {-1*storage.OrientationUnitComponents[entity.orientation].x, -1*storage.OrientationUnitComponents[entity.orientation].y}),
			limit = 1
		})[1]
		-- output arrow
		properties.arrow = rendering.draw_sprite
		{
			sprite = "utility/indication_arrow",
			orientation = (entity.orientation+0.5)%1,
			target = {entity=entity, offset={-0.75*storage.OrientationUnitComponents[entity.orientation].x, -0.75*storage.OrientationUnitComponents[entity.orientation].y}},
			surface = entity.surface,
			only_in_alt_mode = true,
			x_scale = 0.75,
			y_scale = 0.75,
		}
	end
end
)

-- On Rotate
script.on_event(defines.events.on_player_rotated_entity, function(event)
	local entity = event.entity
	if (entity.name == "RTVacuumHatch_standalone") then
		local properties = storage.VacuumHatches_standalone[entity.unit_number]
		if not properties then return end
		properties.output = entity.surface.find_entities_filtered
		({
			collision_mask = "object",
			position = OffsetPosition(entity.position, {-1*storage.OrientationUnitComponents[entity.orientation].x, -1*storage.OrientationUnitComponents[entity.orientation].y}),
			limit = 1
		})[1]
		properties.ParticleAnimation.orientation = entity.orientation
		properties.ParticleAnimation.target = {entity=entity, offset={3*storage.OrientationUnitComponents[entity.orientation].x, 3*storage.OrientationUnitComponents[entity.orientation].y}}
		if (properties.arrow) then
			properties.arrow.orientation = (entity.orientation+0.5)%1
			properties.arrow.target = {entity=entity, offset={-0.75*storage.OrientationUnitComponents[entity.orientation].x, -0.75*storage.OrientationUnitComponents[entity.orientation].y}}
		end
	end
end
)


script.on_event(
	defines.events.on_object_destroyed, function(event)
	if (storage.VacuumHatches_standalone[event.registration_number]) then
		storage.VacuumHatches_standalone[event.registration_number] = nil
	end
end
	
)


-- Animating/On Tick
script.on_nth_tick(1, function(event)
  if (game.tick%3 == 0) then
		for _, VacuumHatchStuff in pairs(storage.VacuumHatches_standalone) do
			if (VacuumHatchStuff.entity.valid and VacuumHatchStuff.entity.energy > 0) then
				if VacuumHatchStuff.ParticleAnimation and not VacuumHatchStuff.ParticleAnimation.visible then -- is this faster than just setting it to true every time?
					VacuumHatchStuff.ParticleAnimation.visible = true
				end
				local VacuumHatch_standalone = VacuumHatchStuff.entity
				if (VacuumHatchStuff.Timeout ~= nil) then
					if (VacuumHatchStuff.Timeout-1 <= 0) then
						VacuumHatchStuff.Timeout = nil
					else
						VacuumHatchStuff.Timeout = VacuumHatchStuff.Timeout - 1
					end
				elseif (VacuumHatchStuff.ToSucc == nil or #VacuumHatchStuff.ToSucc == 0) then
					local XShift = 3*storage.OrientationUnitComponents[VacuumHatch_standalone.orientation].x
					local YShift = 3*storage.OrientationUnitComponents[VacuumHatch_standalone.orientation].y
					local spills = VacuumHatch_standalone.surface.find_entities_filtered({
						type="item-entity",
						area={{VacuumHatch_standalone.position.x-2.5+XShift, VacuumHatch_standalone.position.y-2.5+YShift}, {VacuumHatch_standalone.position.x+2.5+XShift, VacuumHatch_standalone.position.y+2.5+YShift}}
					})
					if (#spills > 0) then
						for i = #spills, 2, -1 do
							local j = math.random(i)
							spills[i], spills[j] = spills[j], spills[i]
						end
						VacuumHatchStuff.ToSucc = spills
					else
						VacuumHatchStuff.Timeout = 60/3 -- cause this function runs every 3 ticks
					end
				end
			else
				if (VacuumHatchStuff.ParticleAnimation and VacuumHatchStuff.ParticleAnimation.visible) then
					VacuumHatchStuff.ParticleAnimation.visible = false
				end
			end
		end
	end
end
)