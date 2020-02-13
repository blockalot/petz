local modpath, S = ...

minetest.register_on_leaveplayer(function(player)
	petz.force_detach(player)	
end)

minetest.register_on_shutdown(function()
	local players = minetest.get_connected_players()
	for i = 1, #players do
		petz.force_detach(players[i])
	end
end)

minetest.register_on_player_hpchange(function(player, hp_change)
	local attached_to = player:get_attach()
	if attached_to then
		local entity = attached_to:get_luaentity()	
		if entity.is_mountable then
			local hp = player:get_hp()
			if hp_change < 0 then
				local new_hp = hp + hp_change
				if new_hp <= 0 then
					petz.force_detach(player)			
				end
			end
		end
	end	
end)

-------------------------------------------------------------------------------

function petz.attach(entity, player)
	local attach_at, eye_offset = {}, {}
	entity.player_rotation = entity.player_rotation or {x = 0, y = 0, z = 0}
	entity.driver_attach_at = entity.driver_attach_at or {x = 0, y = 0, z = 0}
	entity.driver_eye_offset = entity.driver_eye_offset or {x = 0, y = 0, z = 0}
	entity.driver_scale = entity.driver_scale or {x = 1, y = 1}
	local rot_view = 0
	if entity.player_rotation.y == 90 then
		rot_view = math.pi/2
	end
	attach_at = entity.driver_attach_at
	eye_offset = entity.driver_eye_offset
	entity.driver = player	
	petz.force_detach(player)
	player:set_attach(entity.object, "", attach_at, entity.player_rotation)
	default.player_attached[player:get_player_name()] = true	
	player:set_properties({
		visual_size = {
			x = petz.truncate(entity.driver_scale.x, 2),
			y = petz.truncate(entity.driver_scale.y, 2)
		},
		pointable = petz.settings.pointable_driver		
	})
	player:set_eye_offset(eye_offset, {x = 0, y = 0, z = 0})
	minetest.after(0.2, function()
		default.player_set_animation(player, "sit" , 30)
	end)
	player:set_look_horizontal(entity.object:get_yaw() - rot_view)
end

petz.force_detach = function(player)
	local attached_to = player:get_attach()
	if not attached_to then		
		return
	end
	local entity = attached_to:get_luaentity()
	if entity.driver and entity.driver == player then
		entity.driver = nil
	end
	player:set_detach()
	default.player_attached[player:get_player_name()] = false
	player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
	default.player_set_animation(player, "stand" , 30)	
	player:set_properties({
		visual_size = {x = 1, y = 1},
		pointable = true
	})
end

function petz.detach(player, offset)
	petz.force_detach(player)
	local pos = player:get_pos()
	pos = {x = pos.x + offset.x, y = pos.y + 0.2 + offset.y, z = pos.z + offset.z}
	minetest.after(0.1, function()
		player:set_pos(pos)
	end)
end
