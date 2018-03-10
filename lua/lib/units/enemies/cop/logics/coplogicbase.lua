local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_sub = mvector3.subtract
local mvec3_norm = mvector3.normalize
local mvec3_dir = mvector3.direction
local mvec3_set_l = mvector3.set_length
local mvec3_add = mvector3.add
local mvec3_dot = mvector3.dot
local mvec3_cross = mvector3.cross
local mvec3_rot = mvector3.rotate_with
local mvec3_rand_orth = mvector3.random_orthogonal
local mvec3_lerp = mvector3.lerp
local mrot_axis_angle = mrotation.set_axis_angle
local temp_vec1 = Vector3()
local temp_vec2 = Vector3()
local temp_vec3 = Vector3()
local temp_rot1 = Rotation()
local bezier_curve = {
	0,
	0,
	1,
	1
}

function CopLogicBase._set_attention_obj(data, new_att_obj, new_reaction)
	local old_att_obj = data.attention_obj
	data.attention_obj = new_att_obj

	if new_att_obj then
		new_reaction = new_reaction or new_att_obj.settings.reaction
		new_att_obj.reaction = new_reaction
		local new_crim_rec = new_att_obj.criminal_record
		local is_same_obj, contact_chatter_time_ok = nil

		if old_att_obj then
			if old_att_obj.u_key == new_att_obj.u_key then
				is_same_obj = true
				contact_chatter_time_ok = new_crim_rec and data.t - new_crim_rec.det_t > 2

				if new_att_obj.stare_expire_t and new_att_obj.stare_expire_t < data.t then
					if new_att_obj.settings.pause then
						new_att_obj.stare_expire_t = nil
						new_att_obj.pause_expire_t = data.t + math.lerp(new_att_obj.settings.pause[1], new_att_obj.settings.pause[2], math.random())
					end
				elseif new_att_obj.pause_expire_t and new_att_obj.pause_expire_t < data.t then
					if not new_att_obj.settings.attract_chance or math.random() < new_att_obj.settings.attract_chance then
						new_att_obj.pause_expire_t = nil
						new_att_obj.stare_expire_t = data.t + math.lerp(new_att_obj.settings.duration[1], new_att_obj.settings.duration[2], math.random())
					else
						debug_pause_unit(data.unit, "skipping attraction")

						new_att_obj.pause_expire_t = data.t + math.lerp(new_att_obj.settings.pause[1], new_att_obj.settings.pause[2], math.random())
					end
				end
			else
				if old_att_obj.criminal_record then
					managers.groupai:state():on_enemy_disengaging(data.unit, old_att_obj.u_key)
				end

				if new_crim_rec then
					managers.groupai:state():on_enemy_engaging(data.unit, new_att_obj.u_key)
				end

				contact_chatter_time_ok = new_crim_rec and data.t - new_crim_rec.det_t > 15
			end
		else
			if new_crim_rec then
				managers.groupai:state():on_enemy_engaging(data.unit, new_att_obj.u_key)
			end

			contact_chatter_time_ok = new_crim_rec and data.t - new_crim_rec.det_t > 15
		end

		if not is_same_obj then
			if new_att_obj.settings.duration then
				new_att_obj.stare_expire_t = data.t + math.lerp(new_att_obj.settings.duration[1], new_att_obj.settings.duration[2], math.random())
				new_att_obj.pause_expire_t = nil
			end

			new_att_obj.acquire_t = data.t
		end

		if AIAttentionObject.REACT_SHOOT <= new_reaction and new_att_obj.verified and contact_chatter_time_ok and (data.unit:anim_data().idle or data.unit:anim_data().move) and new_att_obj.is_person then
			data.unit:sound():say("c01", true)
		end
	elseif old_att_obj and old_att_obj.criminal_record then
		managers.groupai:state():on_enemy_disengaging(data.unit, old_att_obj.u_key)
	end
end

function CopLogicBase.chk_start_action_dodge(data, reason)
	--print( "[CopLogicBase.chk_start_action_dodge]", reason )
	if not data.char_tweak.dodge or not data.char_tweak.dodge.occasions[reason] then
		--print( "no tweak" )
		return -- this character never dodges for this reason
	end
	-- 1. check if we have timed out the previous dodge
	if data.dodge_timeout_t and data.t < data.dodge_timeout_t or data.dodge_chk_timeout_t and data.t < data.dodge_chk_timeout_t or data.unit:movement():chk_action_forbidden("walk") then
		--print( "cant dodge atm", data.dodge_timeout_t and ( data.dodge_timeout_t - data.t), data.dodge_chk_timeout_t and ( data.dodge_chk_timeout_t - data.t ) )
		return -- cannot dodge atm
	end
	local dodge_tweak = data.char_tweak.dodge.occasions[reason]
	-- 2. roll chance to dodge
	data.dodge_chk_timeout_t = TimerManager:game():time() + math.lerp(dodge_tweak.check_timeout[1], dodge_tweak.check_timeout[2], math.random())
	if dodge_tweak.chance == 0 or dodge_tweak.chance < math.random() then
		--print( "chance fail" )
		return
	end
	-- 3. pick random variation
	local rand_nr = math.random()
	local total_chance = 0
	local variation, variation_data = nil
	for test_variation, test_variation_data in pairs(dodge_tweak.variations) do
		total_chance = total_chance + test_variation_data.chance
		if test_variation_data.chance > 0 and rand_nr <= total_chance then
			variation = test_variation
			variation_data = test_variation_data
			break
		end
	end

	--print( "variation", variation, "variation_data", inspect( variation_data ) )
	
	-- 4. choose direction

	local dodge_dir = Vector3()
	local face_attention = nil
	if data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction then
		mvec3_set(dodge_dir, data.attention_obj.m_pos)
		mvec3_sub(dodge_dir, data.m_pos)
		mvector3.set_z(dodge_dir, 0)
		mvector3.normalize(dodge_dir)
		if mvector3.dot(data.unit:movement():m_fwd(), dodge_dir) < 0 then
			--print( "attention is behind me" )
			return
		end
		--print( "attention dir", dodge_dir )
		mvector3.cross(dodge_dir, dodge_dir, math.UP)
		--print( "dodge_dir from attention", dodge_dir )
		face_attention = true
	else
		mvector3.random_orthogonal(dodge_dir, math.UP)
		--print( "dodge_dir random", dodge_dir )
	end
	local dodge_dir_reversed = false
	if math.random() < 0.5 then
		mvector3.negate(dodge_dir)
		--print( "negating", dodge_dir )
		dodge_dir_reversed = not dodge_dir_reversed
	end
	--Application:set_pause( true )
	--Application:draw_cylinder( data.m_pos, data.m_pos + dodge_dir * 300, 10, 1, 0, 0 )
	--Application:draw_rotation( data.m_pos, data.unit:movement():m_rot() )
	local prefered_space = 200    -- 130 default, changed to 200 which is what was used in PDTH
	-- local min_space = 90    -- DEFAULT!!!!!!
	local min_space = 0
	local ray_to_pos = tmp_vec1
	mvec3_set(ray_to_pos, dodge_dir)
	mvector3.multiply(ray_to_pos, 200)    -- 130 default, changed to 200 which is what was used in PDTH
	mvector3.add(ray_to_pos, data.m_pos)
	local ray_params = {
		trace = true,
		tracker_from = data.unit:movement():nav_tracker(),
		pos_to = ray_to_pos
	}
	local ray_hit1 = managers.navigation:raycast(ray_params)
	local dis = nil
	if ray_hit1 then -- we hit an obstacle on this side. check if there is more space to the other side
		--Application:draw_sphere( ray_params.trace[1], 5, 0, 0, 1 )
		local hit_vec = tmp_vec2
		mvec3_set(hit_vec, ray_params.trace[1])
		mvec3_sub(hit_vec, data.m_pos)
		mvec3_set_z(hit_vec, 0)
		dis = mvector3.length(hit_vec)
		--print( "ray_hit1 dis", dis )
		mvec3_set(ray_to_pos, dodge_dir)
		mvector3.multiply(ray_to_pos, -200)    -- 130 default, changed to 200 which is what was used in PDTH
		mvector3.add(ray_to_pos, data.m_pos)
		ray_params.pos_to = ray_to_pos
		local ray_hit2 = managers.navigation:raycast(ray_params)
		if ray_hit2 then
			--Application:draw_sphere( data.m_pos, 4, 0, 0, 0.7 )
			mvec3_set(hit_vec, ray_params.trace[1])
			mvec3_sub(hit_vec, data.m_pos)
			mvec3_set_z(hit_vec, 0)
			local prev_dis = dis
			dis = mvector3.length(hit_vec)
			--print( "ray_hit2 dis", dis )
			if prev_dis < dis and min_space < dis then
				--print( "negating due to obstacle" )
				mvector3.negate(dodge_dir)
				dodge_dir_reversed = not dodge_dir_reversed
			end
		else
			--print( "negating due to obstacle" )
			mvector3.negate(dodge_dir)
			dis = nil
			dodge_dir_reversed = not dodge_dir_reversed
		end
	end
	if ray_hit1 and dis and dis < min_space then
		--print( "not enough space" )
		return
	end
	--[[local dodge_side = nil    -- Default, below is the modified part
	if face_attention then -- choose side that rotates us towards our attention
		dodge_side = dodge_dir_reversed and "l" or "r"
	else -- choose side closest to the wanted rotation
		local fwd_dot = mvec3_dot(dodge_dir, data.unit:movement():m_fwd())
		local my_right = tmp_vec1
		mrotation.x(data.unit:movement():m_rot(), my_right)
		local right_dot = mvec3_dot(dodge_dir, my_right)
		--print( "fwd_dot", fwd_dot )
		--print( "right_dot", right_dot )
		dodge_side = math.abs(fwd_dot) > 0.7071067690849 and (fwd_dot > 0 and "fwd" or "bwd") or right_dot > 0 and "r" or "l"
	end]]
	local dodge_side
	local fwd_dot = mvec3_dot(dodge_dir, data.unit:movement():m_fwd())
	local my_right = tmp_vec1
	mrotation.x(data.unit:movement():m_rot(), my_right)
	local right_dot = mvec3_dot(dodge_dir, my_right)
	--print( "fwd_dot", fwd_dot )
	--print( "right_dot", right_dot )
	dodge_side = math.abs(fwd_dot) > 0.7071067690849 and (fwd_dot > 0 and "fwd" or "bwd") or right_dot > 0 and "r" or "l"
	local body_part = 1
	local shoot_chance = variation_data.shoot_chance
	if shoot_chance and shoot_chance > 0 and math.random() < shoot_chance then
		body_part = 2
	end
	--print( "dodge_side", dodge_side )
	local action_data = {
		type = "dodge",
		body_part = body_part,
		variation = variation,
		side = dodge_side,
		direction = dodge_dir,
		timeout = variation_data.timeout,
		speed = data.char_tweak.dodge.speed,
		shoot_accuracy = variation_data.shoot_accuracy,
		blocks = {
			act = -1,
			tase = -1,
			bleedout = -1,
			dodge = -1,
			walk = -1,
			action = body_part == 1 and -1 or nil,
			aim = body_part == 1 and -1 or nil
		}
	}
	if variation ~= "side_step" then -- they can play hurts while side-stepping
		action_data.blocks.hurt = -1
		action_data.blocks.heavy_hurt = -1
	end
	local action = data.unit:movement():action_request(action_data)
	if action then
		local my_data = data.internal_data
		CopLogicAttack._cancel_cover_pathing(data, my_data)
		CopLogicAttack._cancel_charge(data, my_data)
		CopLogicAttack._cancel_expected_pos_path(data, my_data)
		CopLogicAttack._cancel_walking_to_cover(data, my_data, true)
	end
	return action
end