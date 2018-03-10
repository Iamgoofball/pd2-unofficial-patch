local origin_init_medic = CharacterTweakData._init_medic
local origin_init_tank = CharacterTweakData._init_tank
local origin_init_gensec = CharacterTweakData._init_gensec
local origin_presets = CharacterTweakData._presets

function CharacterTweakData:_presets(tweak_data)
	presets.surrender.easy = {
		base_chance = 0.3,
		significant_chance = 0.35,
		reasons = {
			health = {
				[1] = 0.1,
				[0.999] = 0.4
			},
			weapon_down = 0.5,
			pants_down = 1,
			isolated = 0.08
		},
		factors = {
			flanked = 0.05,
			unaware_of_aggressor = 0.1,
			enemy_weap_cold = 0.11,
			aggressor_dis = {
				[1000] = 0,
				[300] = 0.2
			}
		}
	}
end

function CharacterTweakData:_init_tank(presets)
	origin_init_tank(presets)
	self.tank.melee_anims = nil
	self.tank.no_recoil = true
end

function CharacterTweakData:_init_medic(presets)
	origin_init_medic(presets)
	self.medic.suppression = nil
end

function CharacterTweakData:_init_gensec(presets)
	origin_init_gensec(presets)
	presets.suppression.hard_def
end

function CharacterTweakData:_multiply_all_speeds(walk_mul, run_mul)
	local all_units = {
		"security",
		"security_undominatable",
		"cop",
		"cop_scared",
		"cop_female",
		"gensec",
		"fbi",
		"swat",
		"heavy_swat",
		"heavy_swat_sniper",
		"sniper",
		"gangster",
		"biker",
		"biker_escape",
		"mobster",
		"bolivian",
		"bolivian_indoors",
		"tank",
		"tank_medic",
		"tank_mini",
		"tank_hw",
		"spooc",
		"shield",
		"phalanx_minion",
		"phalanx_vip",
		"taser",
		"medic",
		"city_swat",
		"fbi_swat",
		"fbi_heavy_swat"
	}
	table.insert(all_units, "bolivian")
	table.insert(all_units, "bolivian_indoors")
	for _, name in ipairs(all_units) do
		local speed_table = self[name].SPEED_WALK
		speed_table.hos = speed_table.hos * walk_mul
		speed_table.cbt = speed_table.cbt * walk_mul
	end
	self.security.SPEED_RUN = self.security.SPEED_RUN * run_mul
	self.security_undominatable.SPEED_RUN = self.security_undominatable.SPEED_RUN * run_mul
	self.cop.SPEED_RUN = self.cop.SPEED_RUN * run_mul
	self.cop_scared.SPEED_RUN = self.cop_scared.SPEED_RUN * run_mul
	self.cop_female.SPEED_RUN = self.cop_female.SPEED_RUN * run_mul
	self.fbi.SPEED_RUN = self.fbi.SPEED_RUN * run_mul
	self.gensec.SPEED_RUN = self.gensec.SPEED_RUN * run_mul
	self.swat.SPEED_RUN = self.swat.SPEED_RUN * run_mul
	self.heavy_swat.SPEED_RUN = self.heavy_swat.SPEED_RUN * run_mul
	self.heavy_swat_sniper.SPEED_RUN = self.heavy_swat_sniper.SPEED_RUN * run_mul
	self.fbi_heavy_swat.SPEED_RUN = self.fbi_heavy_swat.SPEED_RUN * run_mul
	self.sniper.SPEED_RUN = self.sniper.SPEED_RUN * run_mul
	self.gangster.SPEED_RUN = self.gangster.SPEED_RUN * run_mul
	self.biker.SPEED_RUN = self.biker.SPEED_RUN * run_mul
	self.mobster.SPEED_RUN = self.mobster.SPEED_RUN * run_mul
	self.bolivian.SPEED_RUN = self.bolivian.SPEED_RUN * run_mul
	self.bolivian_indoors.SPEED_RUN = self.bolivian_indoors.SPEED_RUN * run_mul
	self.tank.SPEED_RUN = self.tank.SPEED_RUN * run_mul
	self.tank_medic.SPEED_RUN = self.tank_medic.SPEED_RUN * run_mul
	self.tank_mini.SPEED_RUN = self.tank_mini.SPEED_RUN * run_mul
	self.tank_hw.SPEED_RUN = self.tank_hw.SPEED_RUN * run_mul
	self.spooc.SPEED_RUN = self.spooc.SPEED_RUN * run_mul
	self.shield.SPEED_RUN = self.shield.SPEED_RUN * run_mul
	self.phalanx_minion.SPEED_RUN = self.phalanx_minion.SPEED_RUN * run_mul
	self.phalanx_vip.SPEED_RUN = self.phalanx_vip.SPEED_RUN * run_mul
	self.taser.SPEED_RUN = self.taser.SPEED_RUN * run_mul
	self.medic.SPEED_RUN = self.medic.SPEED_RUN * run_mul
	self.city_swat.SPEED_RUN = self.city_swat.SPEED_RUN * run_mul
	self.biker_escape.SPEED_RUN = self.biker_escape.SPEED_RUN * run_mul
	self.fbi_swat.SPEED_RUN = self.fbi_swat.SPEED_RUN * run_mul
end