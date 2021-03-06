DefineClass.City = {
	__parents = { "InitDone", "LabelContainer" },
	properties = {
	},
	day = 1, -- start the game at sol 1
	hour = 6, -- start the game at 6am so the solar panels are immediatelly working
	minute = 0,
	
	electricity = false,
	water = false,
	air = false,
	building_grids = false,	
	dome_networks = false,

	unlocked_upgrades = false,
	
	label_modifiers = false,
	labels = false,
	
	selected_dome = false,
	selected_dome_unit_tracking_thread = false,

	queued_resupply = false,
	
	funding = false,
	funding_gain = false,
	funding_gain_total = false,
	funding_gain_last = false,
	funding_gain_sol = false,
	
	launch_elevator_mode = false, -- todo: remove
	launch_mode = false, -- (false, "rocket", "elevator", ...)
	
	cascade_cable_deletion_enabled = true, --use to disable chunk cable deletion (for building placement for example)		
	cascade_cable_deletion_dsiable_reasons = false,
	
	check_achievements_thread = false,
	
	deposit_depth_exploitation_research_bonus = 0,
	
	--Construction cost modifiers (per building, per stage, per resource, in percent)
	--These are filled only when there is a change
	construction_cost_mods_percent = false,
	construction_cost_mods_amount = false,
	
	mystery_id = "",
	mystery = false,
	
	--tracked resource usage
	gathered_resources_today = false,
	gathered_resources_yesterday = false, --from surf deps, also it's more like current sol.
	gathered_resources_total = false,
	consumption_resources_consumed_yesterday = false,
	consumption_resources_consumed_today = false,
	maintenance_resources_consumed_yesterday = false,
	maintenance_resources_consumed_today = false,
	last_export = false, --last precious metals export info
	total_export = 0,    --total exported precious metals, in resource units
	fuel_for_rocket_refuel_today = 0,
	fuel_for_rocket_refuel_yesterday = 0,
	--

	wasted_electricity_for_rp = 0,
	
	available_prefabs = false,
	compound_effects = false,
	LastConstructedBuilding = false,
	
	research_queue = false,
	tech_status = false,
	tech_field = false,
	discover_idx = 0,
	TechBoostPerField = false,
	TechBoostPerTech = false,
	OutsourceResearchPoints = false,
	OutsourceResearchOrders = false,
	paused_sponsor_research_end_time = false,
	paused_outsource_research_end_time = false,
	
	rand_state = false,
	
	cur_sol_died = 0,
	last_sol_died = 0,
	dead_notification_shown = false,
	
	drone_prefabs = 0,
	
	next_anomaly_day = false,
	next_anomaly_interval = 20, -- sols
	
	-- time series logs for bar graphs in CCC
	ts_colonists = false,
	ts_colonists_unemployed = false,
	ts_colonists_homeless = false,
	ts_drones = false,
	ts_shuttles = false,
	ts_buildings = false,
	ts_constructions_completed = false,
	ts_resources_stockpile = false,
	ts_resources_grid = false,
	constructions_completed_today = false,
	challenge_thread = false,
	challenge_timeout_thread = false,
	
}

function City:Init()
	self:InitRandom()
	
	self.available_prefabs = {}
	self.compound_effects = {}
	self.electricity = SupplyGrid:new{ city = self }
	self.water = SupplyGrid:new{ city = self }
	self.air = SupplyGrid:new{ city = self }
	
	-- call early mod effects init
	for _, effects in ipairs(ModGlobalEffects) do
		effects:EffectsInit(self)
	end
	GetMissionSponsor():EffectsInit(self)
	GetCommanderProfile():EffectsInit(self)
	local rules = GetActiveGameRules()
	for _, rule_id in ipairs(rules) do
		local rule = GameRulesMap[rule_id]
		assert(rule)
		if rule then
			rule:EffectsInit(self)
		end
	end
	
	self:SelectMystery() -- should be before research - research items depend on the current mystery
	self:InitResearch()
	
	self:AddToLabel("Consts", g_Consts)

	local sponsor = GetMissionSponsor()

	--funding and resupply
	self.queued_resupply = {}
	self.funding = 0
	local init_funding = GetSponsorModifiedFunding(sponsor.funding, empty_table)
	self:ChangeFunding(init_funding*1000000 - g_CargoCost, "Sponsor")
	
	if g_RocketCargo then
		g_InitialRocketCargo = table.copy(g_RocketCargo, "deep")
		g_InitialCargoCost = g_CargoCost
		g_InitialCargoWeight = g_CargoWeight
		self:AddResupplyItems(g_RocketCargo)
		ResetCargo()
	else
		ApplyResupplyPreset(self, "Start_medium")
	end
	
	CreateGameTimeThread(function(self)
		self:GameInitResearch()
		self:InitBreakThroughAnomalies()
		self:InitHeat()
		self:InitExploration()
		self:InitMystery()
		if not g_Tutorial or g_Tutorial.EnableRockets then
			self:CreateSupplyShips()
			local cargo = self.queued_resupply
			self.queued_resupply = {}
			Sleep(1) -- wait for rocket GameInits
			assert(self.labels.SupplyRocket and #self.labels.SupplyRocket > 0)
			cargo.rocket_name = g_CurrentMapParams.rocket_name
			MarkNameAsUsed("Rocket",g_CurrentMapParams.rocket_name_base) 
			self:OrderLanding(cargo, 0, true)
		else
			-- cleanup saved rockets
			local rockets = self.labels.SupplyRocket or empty_table
			
			for i = #rockets, 1, -1 do
				if rockets[i]:GetPos() == InvalidPos() then
					DoneObject(rockets[i])
				end
			end
		end
		sponsor:game_apply(self)
		GetCommanderProfile():game_apply(self)
		-- apply mod effects
		for _, effects in ipairs(ModGlobalEffects) do
			effects:EffectsApply(self)
		end
		GetMissionSponsor():EffectsApply(self)
		GetCommanderProfile():EffectsApply(self)
		local rules = GetActiveGameRules()
		for _, rule_id in ipairs(rules) do
			local rule = GameRulesMap[rule_id]
			if rule then
				rule:EffectsApply(self)
			end
		end
		InitApplicantPool()
		self:ApplyModificationsFromProperties()
		self:CheckAvailableTech()
		-- unlock some upgrades by default
		self:UnlockUpgrade("Mohole_ExpandMohole_1")
		self:UnlockUpgrade("Mohole_ExpandMohole_2")
		self:UnlockUpgrade("Mohole_ExpandMohole_3")
		self:UnlockUpgrade("Excavator_ImprovedRefining_1")
		self:UnlockUpgrade("Excavator_ImprovedRefining_2")
		self:UnlockUpgrade("Excavator_ImprovedRefining_3")
	end, self)
	
	self.unlocked_upgrades = {}
	
	self.cascade_cable_deletion_dsiable_reasons = {}
	
	self.construction_cost_mods_percent = {}
	self.construction_cost_mods_amount = {}
	
	--mission related
	self:InitMissionBonuses()
	self:InitGatheredResourcesTables()
	self:InitEmptyLabel("Dome")
	
	if not g_Tutorial and CurrentMap ~= "Mod" then
		self:SetGoals()
		self:StartChallenge()
	end
	
	--lock mystery resource depot from the build menu
	LockBuilding("StorageMysteryResource")
	LockBuilding("MechanizedDepotMysteryResource")
	LockBuilding("TradePad")
	self:InitTimeSeries()
end

GlobalVar("FirstUniversalStorage", false)

function CreateRand(stable, ...)
	local seed = xxhash(...)
	local function rand(max)
		local value
		value, seed = BraidRandom(seed, max, stable)
		return value
	end
	local function trand(tbl, weight)
		local value, idx
		if weight then
			value, idx, seed = table.weighted_rand(tbl, weight, seed, stable)
		else
			idx, seed = BraidRandom(seed, #tbl, stable)
			idx = idx + 1
			value = tbl[idx]
		end
		return value, idx
	end
	return rand, trand
end

function City:CreateSessionRand(...)
	return CreateRand(false, g_SessionSeed, ...)
end

function City:CreateMapRand(...)
	local gen = GetRandomMapGenerator()
	local seed = gen and gen.Seed or AsyncRand()
	return CreateRand(true, seed, ...)
end

function City:CreateResearchRand(...)
	if IsGameRuleActive("ChaosTheory") then
		return AsyncRand
	elseif IsGameRuleActive("TechVariety") then
		return self:CreateSessionRand(...)
	else
		return self:CreateMapRand(...)
	end
end

function City:IsUpgradeUnlocked(id)
	return self.unlocked_upgrades[id] or false
end

function City:UnlockUpgrade(id)
	self.unlocked_upgrades[id] = true
	Msg("UpgradeUnlocked", id, self)
end

function City:SetCableCascadeDeletion(val, reason)
	if val then
		self.cascade_cable_deletion_dsiable_reasons[reason] = nil
		if not next(self.cascade_cable_deletion_dsiable_reasons) then
			self.cascade_cable_deletion_enabled = true
		end
	else
		self.cascade_cable_deletion_dsiable_reasons[reason] = true
		self.cascade_cable_deletion_enabled = false
	end
end

function City:ChangeGlobalConsts()
	-- directly modify global consts (from sponsor
	local sponsor = GetMissionSponsor()
	for _, mod_const in ipairs(directlyModifiableConsts) do
		local mod_id = mod_const.local_id
		local global_const = mod_const.global_id
		if sponsor:HasMember(mod_id) then
			SetGlobalConst(global_const, sponsor[mod_id])
		end
	end
	
	-- modify global consts with labels (from commander)
	local commander = GetCommanderProfile()
	for _, mod_const in ipairs(modifiableConsts) do
		local mod_id = mod_const.local_id
		local global_const = mod_const.global_id
		local lower_bound = g_Consts[global_const] < g_Consts["base_"..global_const] and - g_Consts[global_const] or - g_Consts["base_"..global_const]
		local mod_amount = commander[mod_id] > lower_bound and commander[mod_id] or lower_bound
		if commander:HasMember(mod_id) then
			local scale = ModifiablePropScale[global_const]
			if not scale then
				assert(false, print_format("Trying to modify a non-modifiable property", "Consts", "-", global_const))
				return
			end
			local tech_mod = {Label = "Const", Amount = mod_amount, Prop = global_const}
			self:SetLabelModifier("Consts", tech_mod, Modifier:new{
				prop = global_const,
				amount = mod_amount,
				percent = 0,
				id = commander:HasMember("GetIdentifier") and commander:GetIdentifier() or commander.id,
			})
		end
	end
end

GlobalVar("SponsorGoalProgress", {}) -- goal_id, target, progress, state, GetTargetText, GetProgressText

function AreAllSponsorGoalsCompleted()
	for _, goal_res in ipairs(SponsorGoalProgress) do
		local state = goal_res.state
		if not state or state == "fail" then
			return false
		end
	end
	return true
end

function City:SetGoals()
	local sponsor = GetMissionSponsor()
	for i = 1, g_Consts.SponsorGoalsCount do
		local id = sponsor:GetProperty("sponsor_goal_"..i)
		if id then
			SponsorGoalProgress[i] = {goal_id = id, state = false, GetTargetText = function(self) return self.target or "" end, GetProgressText = function(self) return self.progress or "" end}
			CreateGameTimeThread(function(id)
				local goal = Presets.SponsorGoals.Default[id]
				if not goal then return end
				local param1 = sponsor:GetProperty(string.format("goal_%d_param_1", i))
				local param2 = sponsor:GetProperty(string.format("goal_%d_param_2", i))
				local param3 = sponsor:GetProperty(string.format("goal_%d_param_3", i))
				local res = goal:Completed(SponsorGoalProgress[i], param1, param2, param3, i)
				if goal then
					SponsorGoalProgress[i].state = res and GameTime() or "fail"
					if res then
						SponsorGoalProgress[i].progress = SponsorGoalProgress[i].target
						param1 = ConvertParam(param1)
						param2 = ConvertParam(param2, type(param1)=="number" and param1>0)
						param3 = ConvertParam(param3, type(param2)=="number" and param2>0)
						local context = {param1 = param1, param2 = param2, param3 = param3}
						local reward = sponsor:GetProperty("reward_effect_"..i)
						reward:Execute()
						AddOnScreenNotification("GoalCompleted", OpenMissionProfileDlg, {reward_description = T{reward.Description, reward}, context = context, rollover_title = T(4773, "<em>Goal:</em> "), rollover_text = goal.description})
						Msg("GoalComplete", goal)
						if AreAllSponsorGoalsCompleted() then
							Msg("MissionEvaluationDone")
						end
						return 
					end
				end
			end, id)
		end
	end
end

function City:StartChallenge()
	local challenge = g_CurrentMissionParams.challenge_id and Presets.Challenge.Default[g_CurrentMissionParams.challenge_id]
	if not challenge then
		return
	end
	
	TelemetryChallengeStart(challenge.id)
	
	local params_tbl = {
		start_time = 0, 
		expiration = challenge.time_completed,
		rollover_title = challenge.title,
		rollover_text = challenge.description,
	}
	if challenge.TrackProgress then
		params_tbl.current = 0
		params_tbl.target = challenge.TargetValue
		params_tbl.rollover_text = challenge.description .. Untranslated("<newline><newline>") .. T{challenge.ProgressText, params_tbl}
	else
		params_tbl.rollover_text = challenge.description
	end
	
	self.challenge_thread = CreateGameTimeThread(function(challenge, params_tbl)
		local regs = {}
		if challenge.Init then
			challenge:Init(regs)
		end
		if challenge.TrackProgress then
			while GameTime() < challenge.time_completed do
				local progress = challenge:TickProgress(regs)
				if progress >= challenge.TargetValue and (not challenge.WinCondition or challenge:WinCondition(regs)) then
					break -- win
				elseif progress ~= params_tbl.current then
					params_tbl.current = progress
					params_tbl.rollover_text = challenge.description .. Untranslated("<newline><newline>") .. T{challenge.ProgressText, params_tbl}
					AddOnScreenNotification("ChallengeTimer", nil, params_tbl)
				end
			end
		else	
			challenge:Run()
		end
		
		if IsValidThread(self.challenge_timeout_thread) then
			DeleteThread(self.challenge_timeout_thread)			
		end
		RemoveOnScreenNotification("ChallengeTimer")
		
		if GameTime() <= challenge.time_completed then
			local score = 0
			ForEachPreset("Milestone", function(o)
				local cs = o:GetChallengeScore()
				if cs then
					score = score + cs
				end
			end)
			
			AccountStorage.CompletedChallenges = AccountStorage.CompletedChallenges or {}
			local record = AccountStorage.CompletedChallenges[challenge.id]
			if type(record) ~= "table" or record.time > GameTime() then
				record = {
					time = GameTime(),
					score = score,
				}
				AccountStorage.CompletedChallenges[challenge.id] = record
				SaveAccountStorage(5000)
			end
			local perfected = GameTime() <= challenge.time_perfected
			Msg("ChallengeCompleted", challenge, perfected)
			while true do
				local preset = perfected and "Challenge_Perfected" or "Challenge_Completed"
				local res = WaitPopupNotification(preset, {
					challenge_name = challenge.title,
					challenge_sols = challenge.time_completed / const.DayDuration,
					perfected_sols = challenge.time_perfected / const.DayDuration,
					elapsed_sols = 1+ GameTime() / const.DayDuration,
					score = score,
				})
				if res == 1 then
					TelemetryChallengeEnd(challenge.id, perfected and "perfected" or "completed", true)
					CreateRealTimeThread(GallerySaveDefaultScreenshot, challenge.id)
					WaitMsg("ChallengeDefaultScreenshotSaved")
					break -- keep playing
				elseif res == 2 then
					OpenPhotoMode(challenge.id)
					WaitMsg("ChallengeScreenshotSaved")
				elseif res == 3 then
					CreateRealTimeThread(function()
						LoadingScreenOpen("idLoadingScreen", "challenge completed")
						TelemetryChallengeEnd(challenge.id, perfected and "perfected" or "completed", false)
						GallerySaveDefaultScreenshot(challenge.id)
						OpenPreGameMainMenu()
						LoadingScreenClose("idLoadingScreen", "challenge completed")
					end)
					break
				end
			end
		end
	end, challenge, params_tbl)
	
	self.challenge_timeout_thread = CreateGameTimeThread(function(self, challenge, params_tbl)
		-- add notification with countdown
		params_tbl.expiration2 = challenge.time_perfected
		params_tbl.additional_text = T(10489, "<newline>Perfect time: <countdown2>")
		if challenge.TrackProgress then
			params_tbl.rollover_text = challenge.description .. Untranslated("<newline><newline>") .. T{challenge.ProgressText, params_tbl}
		end
		AddOnScreenNotification("ChallengeTimer", nil, params_tbl)
		Sleep(challenge.time_perfected)
		params_tbl.expiration2 = nil
		params_tbl.additional_text = nil
		if challenge.TrackProgress then
			params_tbl.rollover_text = challenge.description .. Untranslated("<newline><newline>") .. T{challenge.ProgressText, params_tbl}
		end
		AddOnScreenNotification("ChallengeTimer", nil, params_tbl)
		Sleep(challenge.time_completed - challenge.time_perfected)
		RemoveOnScreenNotification("ChallengeTimer")
					
		if IsValidThread(self.challenge_thread) then
			DeleteThread(self.challenge_thread)
		end
		
		-- popup fail message, exit to main menu if the player chooses
		local res = WaitPopupNotification("Challenge_Failed", {
					challenge_name = challenge.title,
					challenge_sols = challenge.time_completed / const.DayDuration,
					perfected_sols = challenge.time_perfected / const.DayDuration,
					elapsed_sols = 1 + GameTime() / const.DayDuration,
				})
		if res == 3 then
			TelemetryChallengeEnd(challenge.id, "failed", false)
			CreateRealTimeThread(OpenPreGameMainMenu)
		elseif res == 2 then
			TelemetryChallengeEnd(challenge.id, "failed", false)
			CreateRealTimeThread(function()
				LoadingScreenOpen("idLoadingScreen", "restart map")
				TelemetryRestartSession()
				g_SessionSeed = g_InitialSessionSeed
				g_RocketCargo = g_InitialRocketCargo
				g_CargoCost = g_InitialCargoCost
				g_CargoWeight = g_InitialCargoWeight
				GenerateCurrentRandomMap()
				LoadingScreenClose("idLoadingScreen", "restart map")
			end)
		else
			TelemetryChallengeEnd(challenge.id, "failed", true)
		end
	end, self, challenge, params_tbl)
end

function SetGlobalConst(global_const, amount)
	local scale = ModifiablePropScale[global_const]
	if not scale then
		assert(false, print_format("Trying to modify a non-modifiable property", "Consts", "-", global_const))
		return
	end
	g_Consts[global_const] = amount
end

function City:GrantTechFromProperties(source)
	for i=1, 5 do
		local tech_name = source["tech"..i]
		self:SetTechResearched(tech_name)
	end
end

function City:ApplyModificationsFromProperties()
	local sponsor = GetMissionSponsor()
	self:GrantTechFromProperties(sponsor)
	
	local commander = GetCommanderProfile()
	self:GrantTechFromProperties(commander)
end

function City:InitMissionBonuses()
	local sponsor = GetMissionSponsor()
	--Initial cargo capacity (funding is set in City:Init)
	g_Consts:SetBase("CargoCapacity", sponsor.cargo)
	self:ChangeGlobalConsts()

	CreateGameTimeThread( function()
		while true do
			local period = Max(const.HourDuration, g_Consts.SponsorFundingInterval or const.DayDuration)
			local amount = g_Consts.SponsorFundingPerInterval * 1000000
			Sleep(period)
			if amount > 0 then
				amount = self:ChangeFunding( amount, "Sponsor" )
				AddOnScreenNotification( "PeriodicFunding", nil, { sponsor = sponsor.display_name or "", number = amount } )
			end
		end
	end )
end

function City:InitRandom()
	g_SessionSeed = g_SessionSeed or AsyncRand()
	g_InitialSessionSeed = g_SessionSeed
	self.rand_state = RandState(g_SessionSeed)
end

function City:Random(min, max)
	return self.rand_state:Get(min, max)
end

function City:TableRand(tbl)
	local idx = 1 + self:Random(#tbl)
	return tbl[idx], idx
end

function City:LabelRand(label)
	return self:TableRand(self.labels[label] or empty_table)
end

function City:DailyUpdate(day)
	self:GatheredResourcesOnDailyUpdate()
	self:CalcRenegades()
	self:UpdateTimeSeries()
	self:UpdatePlanetaryAnomalies(day)
	
	self.last_sol_died = self.cur_sol_died
	self.cur_sol_died = 0
	
	if IsGameRuleActive("EndlessSupply") and FirstUniversalStorage and IsValid(FirstUniversalStorage) then
		FirstUniversalStorage:Fill()
	end
	local colonists = #(self.labels.Colonist or empty_table)
	ColonistHeavyUpdateTime = Clamp(colonists / 300, 0, 12) * const.HourDuration
	
	self.funding_gain_sol = self.funding_gain
	self.funding_gain = false
end

function OnMsg.CityStart()
	if g_Tutorial then return end
	for _, city in ipairs(Cities) do
		city.next_anomaly_day = 10 + city:Random(2)
	end
end

function City:UpdatePlanetaryAnomalies(day)
	if g_Tutorial or not self.next_anomaly_day or day < self.next_anomaly_day then
		return
	end
	
	self.next_anomaly_day = day + self.next_anomaly_interval + self:Random(5)
	self.next_anomaly_interval = Min(100, self.next_anomaly_interval + 20)
		
	local num = 2 + self:Random(3) -- todo: stable somehow
	local lat, long
	for i = 1, num do
		lat, long = GenerateMarsScreenPoI("anomaly")
		local obj = PlaceObject("PlanetaryAnomaly", {
			display_name = T(11234, "Planetary Anomaly"),
			longitude = long,
			latitude = lat,			
		})
	end
	local function CenterOnSpawnedAnomaly()
		MarsScreenMapParams.latitude = lat
		MarsScreenMapParams.longitude = long
		OpenPlanetaryView()
	end

	AddOnScreenNotification("NewPlanetaryAnomalies", CenterOnSpawnedAnomaly, {count = num})
end

function City:ElectricityToResearch(amount, hours)
	if g_Consts.ElectricityForResearchPoint <= 0 then
		return 0
	end
	
	local full_effect_threshold = 500 * const.ResourceScale
	local full_effect_amount = Min(full_effect_threshold, amount)
	local partial_effect_amount = Max(0, amount - full_effect_threshold)
	
	hours = hours or 1
	local rp, rem
	
	rp = MulDivRound(full_effect_amount, hours, g_Consts.ElectricityForResearchPoint)
	if partial_effect_amount > 0 then
		rp = rp + MulDivRound(partial_effect_amount, hours, 4 * g_Consts.ElectricityForResearchPoint)
		rem = partial_effect_amount % (4 * g_Consts.ElectricityForResearchPoint)
	else
		rem = full_effect_amount % g_Consts.ElectricityForResearchPoint
	end
	
	return rp, rem
end

function City:UpdatePauseEndTimeProp(prop)
	if self[prop] then
		if GameTime() >= self[prop] then
			self[prop] = false
		end
	end
end

function City:HourlyUpdate(hour)
	local rp = 0 
	-- calculate with accumulation for precision, as RPs aren't scaled up
	if g_Consts.ElectricityForResearchPoint ~= 0 then
		for i = 1, #self.electricity do
			self.wasted_electricity_for_rp = self.wasted_electricity_for_rp + self.electricity[i].current_waste 
		end
		local pts, remainder = self:ElectricityToResearch(self.wasted_electricity_for_rp)
		rp = rp + pts
		self.wasted_electricity_for_rp = remainder
	end
	
	self:UpdatePauseEndTimeProp("paused_sponsor_research_end_time")
	if not self.paused_sponsor_research_end_time then
		rp = rp + self:CalcSponsorResearchPoints(const.HourDuration)
	end
	
	rp = rp + self:AddExplorerResearchPoints()

	self:UpdatePauseEndTimeProp("paused_outsource_research_end_time")
	local pts = self.OutsourceResearchPoints[1]
	if pts and not self.paused_outsource_research_end_time then
		table.remove(self.OutsourceResearchPoints, 1)
		table.remove(self.OutsourceResearchOrders, 1)
		rp = rp + pts
	end
	
	self:AddResearchPoints(rp)

	CreateGameTimeThread(self.UpdateColonistsProc, self)
	
	if g_DustStorm and hour % const.BreakIntervalHours == 0 then
		self:RandomBreakSupplyGrid()
	end
end

function City:UpdateColonistsProc()
	local colonists = table.copy(self.labels.Colonist or empty_table)
	local update_interval = const.ColonistUpdateInterval or 50
	local update_steps = const.HourDuration / update_interval
	for i = 1, update_steps do
		local t = GameTime()
		local hour = self.hour
		for j = #colonists * (i - 1) / update_steps + 1, #colonists * i / update_steps do
			local colonist = colonists[j]
			if IsValid(colonist) and not colonist:IsDying() then
				colonist:HourlyUpdate(t, hour)
			end
		end
		Sleep(update_interval)
	end
end

function City:RandomBreakSupplyGrid()
	self.electricity:RandomBreakElements()
	self.water:RandomBreakElements()
end

function City:CalcRenegades()
	local all_colonists = #(self.labels.Colonist or empty_table)
	local colonist_count_threshold = IsGameRuleActive("RebelYell") and 20 or 50
	if all_colonists<=colonist_count_threshold then return end
	
	for idx, dome in ipairs(self.labels.Dome) do
		all_colonists = all_colonists - #(dome.labels.Child or empty_table)
		if all_colonists <= colonist_count_threshold then return end
	end
	
	for idx, dome in ipairs(self.labels.Dome) do
		dome:CalcRenegades()
	end
end

function City:IncrementDepositDepthExploitationLevel(amount)
	self.deposit_depth_exploitation_research_bonus = self.deposit_depth_exploitation_research_bonus + amount
end

function City:GetMaxSubsurfaceExploitationLayer()
	return 1 + self.deposit_depth_exploitation_research_bonus
end

function City:Gossip(gossip, ...)
	if not netAllowGossip then return end
	NetGossip(gossip, GameTime(), ...)
end
-------------- gathered resources
function City:InitGatheredResourcesTables()
	--conditional init so it can be used on save game load.
	self.gathered_resources_total = self.gathered_resources_total or {}
	self.gathered_resources_yesterday = self.gathered_resources_yesterday or {}
	self.gathered_resources_today = self.gathered_resources_today or {}
	self.consumption_resources_consumed_today = self.consumption_resources_consumed_today or {}
	self.consumption_resources_consumed_yesterday = self.consumption_resources_consumed_yesterday or {}
	self.maintenance_resources_consumed_today = self.maintenance_resources_consumed_today or {}
	self.maintenance_resources_consumed_yesterday = self.maintenance_resources_consumed_yesterday or {}
	
	for i = 1, #AllResourcesList do
		local r_n = AllResourcesList[i]
		self.gathered_resources_total[r_n] = self.gathered_resources_total[r_n] or 0
		self.gathered_resources_today[r_n] = self.gathered_resources_today[r_n] or 0
		self.gathered_resources_yesterday[r_n] = self.gathered_resources_yesterday[r_n] or 0
		self.consumption_resources_consumed_today[r_n] = self.consumption_resources_consumed_today[r_n] or 0
		self.consumption_resources_consumed_yesterday[r_n] = self.consumption_resources_consumed_yesterday[r_n] or 0
		self.maintenance_resources_consumed_today[r_n] = self.maintenance_resources_consumed_today[r_n] or 0
		self.maintenance_resources_consumed_yesterday[r_n] = self.maintenance_resources_consumed_yesterday[r_n] or 0
	end
end

function City:GatheredResourcesOnDailyUpdate()
	for i = 1, #AllResourcesList do
		local r_n = AllResourcesList[i]
		self.gathered_resources_yesterday[r_n] = self.gathered_resources_today[r_n]
		self.gathered_resources_today[r_n] = 0
		
		self.consumption_resources_consumed_yesterday[r_n] = self.consumption_resources_consumed_today[r_n]
		self.consumption_resources_consumed_today[r_n] = 0
		
		self.maintenance_resources_consumed_yesterday[r_n] = self.maintenance_resources_consumed_today[r_n]
		self.maintenance_resources_consumed_today[r_n] = 0
	end
	
	self.fuel_for_rocket_refuel_yesterday = self.fuel_for_rocket_refuel_today
	self.fuel_for_rocket_refuel_today = 0
end

function City:OnResourceGathered(r_type, r_amount)
	self.gathered_resources_today[r_type] = self.gathered_resources_today[r_type] + r_amount
	self.gathered_resources_total[r_type] = self.gathered_resources_total[r_type] + r_amount
end

function City:OnConsumptionResourceConsumed(r_type, r_amount)
	self.consumption_resources_consumed_today[r_type] = self.consumption_resources_consumed_today[r_type] + r_amount
end

function City:OnMaintenanceResourceConsumed(r_type, r_amount)
	self.maintenance_resources_consumed_today[r_type] = self.maintenance_resources_consumed_today[r_type] + r_amount
end

function City:MarkPreciousMetalsExport(amount)
	if amount <= 0 then return end
	self.last_export = {amount = amount, day = self.day, hour = self.hour, minute = self.minute}
	self.total_export = self.total_export + amount
	Msg("MarkPreciousMetalsExport", self, amount, self.total_export)
end

function City:FuelForRocketRefuelingDelivered(amount)
	self.fuel_for_rocket_refuel_today = self.fuel_for_rocket_refuel_today + amount
end

-------------- speed buttons
local last_speed = 1
function City:SetGameSpeed(factor)
	local current_factor = GetTimeFactor() / const.DefaultTimeFactor
	if factor and factor < current_factor  then
		PlayFX(factor == 0 and "GamePause" or "GameSpeedDown", "start")
	elseif not factor or (factor and factor > current_factor) then
		if current_factor == 0 then
			PlayFX("GamePause", "end")
		else
			PlayFX("GameSpeedUp", "start")
		end
	end
	factor = factor or last_speed
	if factor ~= current_factor then
		if factor == 0 then
			Msg("MarsPause")
		elseif current_factor == 0 and factor > current_factor then
			Msg("MarsResume")
		end
	end
	if factor > 0 then last_speed = factor end
	UICity:Gossip("GameSpeed", factor)
	SetTimeFactor(const.DefaultTimeFactor * factor, true)
	HUDUpdateTimeButtons()
	
	HintDisable("HintGameSpeed")
end

---- Construction cost modifications
GlobalVar("g_StoryBitConstructionCostModifications", {}) --[building_name] = {[resource] = {[amount] = number, [percent] = number}
local function GetStoryBitConstructionCostModsFor(building_name, resource)
	local data = g_StoryBitConstructionCostModifications
	data[building_name] = data[building_name] or {}
	data = data[building_name]
	data[resource] = data[resource] or {}
	return data[resource]
end

function City:ModifyConstructionCost(action, building, resource, percent, amount, id)
	--extract the building name
	local building_name = building
	if type(building) == "table" then
		if IsKindOf(building, "BuildingTemplate") then
			building_name = building.name
		elseif IsValid(building) then
			building_name = building.class
		end
	end
	
	--Cost modifiers are first indexed by building (the object, see above)
	local all_costs_percent = self.construction_cost_mods_percent
	local building_costs_percent = all_costs_percent[building_name] or {}
	all_costs_percent[building_name] = building_costs_percent
	
	local all_costs_amount = self.construction_cost_mods_amount
	local building_costs_amount = all_costs_amount[building_name] or {}
	all_costs_amount[building_name] = building_costs_amount
	
	--finally by the resource for that stage
	if not building_costs_percent[resource] then
		building_costs_percent[resource] = 100
	end
	
	if not building_costs_amount[resource] then
		building_costs_amount[resource] = 0
	end
	
	if id == "StoryBit" then
		if action == "add" or action == "remove" then
			local data = GetStoryBitConstructionCostModsFor(building_name, resource)
			data.amount = (data.amount or 0) + amount * (action == "remove" and -1 or 1)
			data.percent = (data.percent or 0) + percent * (action == "remove" and -1 or 1)
		end
	end
	
	if action == "add" then
		building_costs_percent[resource] = building_costs_percent[resource] + (percent or 0)
		building_costs_amount[resource] = building_costs_amount[resource] + (amount or 0)
	elseif action == "remove" then
		building_costs_percent[resource] = building_costs_percent[resource] - (percent or 0)
		building_costs_amount[resource] = building_costs_amount[resource] - (amount or 0)
	elseif action == "reset" then
		if id == "StoryBit" then
			local data = GetStoryBitConstructionCostModsFor(building_name, resource)
			building_costs_percent[resource] = building_costs_percent[resource] - (data.percent or 0)
			building_costs_amount[resource] = building_costs_amount[resource] - (data.amount or 0)
		else
			building_costs_percent[resource] = 100
			building_costs_amount[resource] = 0
		end
	else
		error("Incorrect cost modification action")
	end
end

function City:GetConstructionCost(building, resource, modifier_obj)
	if building == "" then return 0 end
	
	--extract the building name
	local building_name = building
	if type(building) == "table" then
		if IsKindOf(building, "BuildingTemplate") then
			building_name = building.id
		elseif building:HasMember("class") then
			building_name = building.class
		end
	end
	
	--base value
	local cost_prop_prefix = "construction_cost_"
	local prop_id = cost_prop_prefix..resource
	local value = building[prop_id]
	
	if building:IsKindOf("Passage") then
		local costs = building.elements and #building.elements > 0 and building.elements[#building.elements].construction_cost_at_completion
		if costs and costs[resource] then
			value = costs[resource]
		end
	end
	
	if modifier_obj then --apply lbl modifiers
		value = modifier_obj:ModifyValue(value, prop_id)
	end
	
	--apply global cost modifier
	value = g_Consts:ModifyValue(value, resource.."_cost_modifier")
	
	--apply dome-only cost modifier
	if IsKindOf(g_Classes[building.template_class], "Dome") then
		value = g_Consts:ModifyValue(value, resource.."_dome_cost_modifier")
	end
	
	--apply building-stage-resource modifier
	local building_costs_percent = self.construction_cost_mods_percent[building_name] or empty_table
	local percent_modifier = building_costs_percent[resource] or 100
	local building_costs_amount = self.construction_cost_mods_amount[building_name] or empty_table
	local amount_modifier = building_costs_amount[resource] or 0
	return MulDivRound(value, percent_modifier, 100) + amount_modifier
end

function OnMsg.LoadGame() --patch to fix old saves (see bug:0122359)
	local city = UICity
	if city then
		local modifiers = city.construction_cost_mods_percent
		local modifier_keys = table.keys(modifiers)
		for _,key in ipairs(modifier_keys) do
			if type(key) == "table" then
				if IsKindOf(key, "BuildingTemplate") then
					modifiers[key.id] = modifiers[key]
				elseif IsValid(key) then
					modifiers[key.class] = modifiers[key]
				end
				
				modifiers[key] = nil
			end
		end
		--fix resource tracking from old saves (init it if it aint inited).
		city:InitGatheredResourcesTables()
	end
end



function City:SetMystery(mys)
	assert(self.mystery == false, "Only one mystery per playthrough.")
	self.mystery = mys
end

---------------------Dome------------------------

function City:SelectDome(dome, trigger)
	if self.selected_dome == dome then return end
	if self.selected_dome then
		if IsValid(self.selected_dome) then
			local bm = GetDialog("XBuildMenu")
			if not bm or bm.context.selected_dome ~= self.selected_dome then --handles special case when build menu is being opened, it will take care of the closing for us.
				self.selected_dome:Close()
			end
		else
			self.selected_dome = false
		end
	end
	
	if IsValidThread(self.selected_dome_unit_tracking_thread) then
		DeleteThread(self.selected_dome_unit_tracking_thread)
	end
	
	self.selected_dome = dome
	
	if self.selected_dome then
		self.selected_dome:Open()
		if IsKindOf(trigger, "Unit") then
			--keep track when the unit will exit the dome.
			self.selected_dome_unit_tracking_thread = CreateGameTimeThread(function()
				while self.selected_dome == dome and IsValid(trigger) and IsValid(SelectedObj)
					and trigger == SelectedObj and
					((SelectedObj:GetPos() == InvalidPos() and SelectedObj:HasMember("holder") and IsValid(SelectedObj.holder) and IsObjInDome(SelectedObj.holder) == self.selected_dome)
					or (IsObjInDome(SelectedObj) == self.selected_dome) 
					or HexGetBuilding(WorldToHex(SelectedObj)) == self.selected_dome) do
					Sleep(1000)
				end
				
				if self.selected_dome == dome then
					CreateRealTimeThread(function()
						self:SelectDome(false)
					end)
				end
				
			end)
		end
	end
end

function OnMsg.SelectionChange()
	local dome_to_select = IsKindOf(SelectedObj, "Dome") and SelectedObj or IsObjInDome(SelectedObj)
	UICity:SelectDome(dome_to_select, SelectedObj)
end

function City:CountDomeLabel(label)
	local count = 0
	local domes = self.labels.Dome or ""
	for i = 1,#domes do
		count = count + #(domes[i].labels[label] or "")
	end
	return count
end

-------------Resupply------------------

function City:CreateSupplyShips()
	local rockets = self.labels.SupplyRocket or empty_table
	
	for i = #rockets, 1, -1 do
		if not rockets[i]:IsValidPos() then
			DoneObject(rockets[i])
		end
	end
	
	for i = #rockets+1, GetStartingRockets() do
		PlaceBuilding(GetRocketClass(), {city = self})
	end
end

function GetStartingRockets(sponsor, commander, ignore_bonus_rockets)
	sponsor = sponsor or GetMissionSponsor()
	commander = commander or GetCommanderProfile()
	return (sponsor.initial_rockets or 0) + (not ignore_bonus_rockets and commander.bonus_rockets or 0)
end

function City:OrderLanding(cargo, cost, initial, label)
	label = label or "SupplyRocket"
	local rockets = self.labels[label] or empty_table
	for i = 1, #rockets do
		local rocket = rockets[i]
		if initial and rocket:IsValidPos() then
			return
		end
		if rocket:IsAvailable() then
			rocket:SetCommand("FlyToMars", cargo, cost, nil, initial)
			return 
		end
	end
end

function City:UseInventoryItem(obj,class, amount)
end
--------------------- funding & resupply ---------------------

function City:CalcBaseExportFunding(amount)
	return MulDivRound(amount or 0, g_Consts.ExportPricePreciousMetals*1000000, const.ResourceScale)
end

function City:CalcModifiedFunding(amount)
	amount = amount or 0
	if amount > 0 then
		amount = MulDivRound(amount, g_Consts.FundingGainsModifier, 100)
	end
	return amount
end

function City:ChangeFunding(amount, source)
	amount = self:CalcModifiedFunding(amount)
	if amount == 0 then
		return
	end
	if (source or "") == "" then
		source = "Other"
	end
	if amount > 0 then
		self.funding_gain_total = self.funding_gain_total or {}
		self.funding_gain_last = self.funding_gain_last or {}
		self.funding_gain = self.funding_gain or {}
		
		self.funding_gain_total[source] = (self.funding_gain_total[source] or 0) + amount
		self.funding_gain[source] = (self.funding_gain[source] or 0) + amount
		self.funding_gain_last[source] = amount
	end
	self.funding = self.funding + amount
	Msg("FundingChanged", self, amount, source)
	return amount
end

function City:GetTotalFundingGain()
	local sum = 0
	for _, category in pairs(self.funding_gain_total or empty_table) do
		sum = sum + category
	end
	return sum
end

function City:GetFunding()
	return self.funding
end

function City:GetWorkshopWorkersPercent()
	local colonists = (self.labels.Colonist or empty_table)
	local workshops = self.labels.Workshop or empty_table
	if #colonists==0 or #workshops==0 then 
		return 0 
	end
	local col_count = 0
	for _, colonist in ipairs(colonists) do
		if colonist:CanWork() then
			col_count = col_count + 1
		end
	end
	if col_count==0 then 
		return 0 
	end
	local workers= 0
	for _, workshop in ipairs(workshops) do
		if workshop.working then
			for i=1, workshop.max_shifts do
				workers = workers + #workshop.workers[i]				
			end
		end
	end
	if workers==0 then 
		return 0 
	end
	return MulDivRound(workers, 100, col_count)
end

function OnMsg.TechResearched(tech_id, city, first_time)
	if not first_time then
		return
	end
	local sponsor = GetMissionSponsor()
	if not city:IsTechDiscoverable(tech_id) then
		city:ChangeFunding( sponsor.funding_per_breakthrough*1000000, "Sponsor" )
		local now = GameTime()
		for i=1,sponsor.applicants_per_breakthrough do
			GenerateApplicant(now, city)
		end
	else
		city:ChangeFunding( sponsor.funding_per_tech*1000000, "Sponsor"  )
	end
end

CargoCapacityLabels = {}

function City:GetCargoCapacity()
	--if self.launch_elevator_mode and #(self.labels.SpaceElevator or empty_table) > 0 then
	local label = CargoCapacityLabels[self.launch_mode]
	if label then
		local obj = (self.labels[label] or empty_table)[1]
		return obj and obj.cargo_capacity or 0
	end
	return g_Consts.CargoCapacity
end

function City:AddResupplyItems(items)
	local inventory = self.queued_resupply
	for i = 1, #items do
		local item = items[i]
		local idx = table.find(inventory, "class", item.class)
		if idx then
			inventory[idx].amount = inventory[idx].amount + item.amount
		elseif item.amount > 0 then
			inventory[#inventory + 1] = item
		end
	end	
end

function City:GetPrefabs(bld)
	return self.available_prefabs[bld] or 0
end

function City:AddPrefabs(bld, count, refresh)
	self.available_prefabs[bld] = (self.available_prefabs[bld] or 0) + count
	if refresh==nil or refresh==true then
		RefreshXBuildMenu()
	end
end

function City:RegisterBuildingCompleted(bld)
	self.LastConstructedBuilding = bld
end

function OnMsg.ConstructionComplete(bld)
	if not mapdata.GameLogic then return end
	assert(bld.city)
	bld.city:RegisterBuildingCompleted(bld)
end

GlobalVar("Cities", {})
GlobalVar("UICity", false)
function OnMsg.NewMap()
	-- cities
	if not mapdata.GameLogic then return end
	Cities[1] = City:new()
	UICity = Cities[1]
	CityConstruction[UICity] = ConstructionController:new()
	CityGridConstruction[UICity] = GridConstructionController:new()
	CityGridSwitchConstruction[UICity] = GridSwitchConstructionController:new()
	CityTunnelConstruction[UICity] = TunnelConstructionController:new()
	CityUnitController[UICity] = UnitController:new()
	Msg("CityStart")
end

function OnMsg.ChangeMap()
	if not mapdata.GameLogic then return end
	SetTimeFactor(const.DefaultTimeFactor)
end

function LocalToEarthTime(time)
	return MulDivRound(time, 24, const.HoursPerDay)
end

function EarthToLocalTime(time)
	return MulDivRound(time, const.HoursPerDay, 24)
end

GlobalVar("NormalLightmodelList", "TheMartian")
function SetNormalLightmodelList(list_name)
	local list_name = list_name or NormalLightmodelList
	if list_name == NormalLightmodelList then return end
	NormalLightmodelList = list_name
	local lm = FindPrevLightmodel(list_name, NextHour*60)
	SetLightmodel(1, lm.id, const.HourDuration)
end

GlobalVar("DisasterLightmodelList", false)
function SetDisasterLightmodelList(list_name, fade_time)
	local list_name = list_name 
	if list_name == DisasterLightmodelList then return end
	DisasterLightmodelList = list_name
	
	list_name = list_name or NormalLightmodelList
	
	local lm = FindPrevLightmodel(list_name, NextHour*60)
	SetLightmodel(1, lm.id, fade_time or const.HourDuration)
end

function GetCurrentLightmodelList()
	return DisasterLightmodelList or NormalLightmodelList
end

function DisasterEventLightmodelHandler()
	SetDisasterLightmodelList(GetDisasterLightmodelList())
end

OnMsg.DustStorm = DisasterEventLightmodelHandler
OnMsg.ColdWave = DisasterEventLightmodelHandler
OnMsg.DustStormEnded = DisasterEventLightmodelHandler
OnMsg.ColdWaveEnded = DisasterEventLightmodelHandler

GlobalVar("SunAboveHorizon", false)
GlobalVar("CurrentWorkshift", 2)
GlobalVar("DayStart", 0)

function OnMsg.NewHour(hour)
	local workshifts = const.DefaultWorkshifts
	if hour == workshifts[1][1] then
		-- at sunrise, first turn solar panels on, then change workshift !!!
		SunAboveHorizon = true
		Msg("SunChange")
		CurrentWorkshift = 1
		Msg("NewWorkshift", 1)
	elseif hour == workshifts[2][1] then
		CurrentWorkshift = 2
		Msg("NewWorkshift", 2)
	elseif hour == workshifts[3][1] then
		-- at set, first change workshift, then turn solar panels off !!!
		CurrentWorkshift = 3
		Msg("NewWorkshift", 3)
		SunAboveHorizon = false
		Msg("SunChange")
	end
end

function OnMsg.NewHour(hour)
	for _, city in ipairs(Cities) do
		city.hour = hour
		city:HourlyUpdate(hour)
	end
end

function OnMsg.NewDay(day)
	for _, city in ipairs(Cities) do
		city.day = day
		city:DailyUpdate(day)
	end
end

function OnMsg.NewMinute(hour, minute)
	for _, city in ipairs(Cities) do
		city.minute = minute
	end
end

function TimeToDayHour(time)
	time = time / const.HourDuration + City.hour -- time is in sol hours now
	return City.day + time / const.HoursPerDay, time
end

GlobalGameTimeThread( "DateTimeThread", function()
	if not mapdata.GameLogic then
		return
	end
	local hour_duration = const.HourDuration
	local minute_duration = const.MinuteDuration
	local minutes_per_hour = const.MinutesPerHour
	local day, hour, minute = City.day, City.hour, 0
	local workshifts = const.DefaultWorkshifts
	CurrentWorkshift = 3
	for i = 1, 2 do
		if hour >= workshifts[i][1] and hour < workshifts[i][2] then
			CurrentWorkshift = i
			SunAboveHorizon = true
			break
		end
	end
	
	SetTimeOfDay(LocalToEarthTime(hour*60*1000), const.HourDuration)
	local lm = FindNextLightmodel(GetCurrentLightmodelList(), hour*60)
	SetLightmodel(1, lm.id, 0)
	InitNightLightState()
	
	Msg("NewDay", day)
	Msg("NewHour", hour)
	while true do
		Sleep(minute_duration)
		minute = minute + 1
		
		if minute == minutes_per_hour then	
			minute = 0
			hour = hour + 1
			if hour == const.HoursPerDay then
				hour = 0
				day = day + 1
			end
		end
		Msg("NewMinute", hour, minute)
		if minute == 0 then
			--@@@msg NewHour,hour- fired every _GameTime_ hour.
			Msg("NewHour", hour)
			if hour == 0 then
				DayStart = GameTime()
				--@@@msg NewDay,day- fired every Sol.
				Msg("NewDay", day)
			end
		end
	end
end )

function GetTimeOfDay()
	if Cities[1] then
		return Cities[1].hour, Cities[1].minute
	end
	return 0
end

function IsDarkHour(hour)
	return hour<=3 or hour>=21
end

function OnMsg.PostNewMapLoaded()
	if mapdata.GameLogic then
		StartScenarios()
	end
end

function CalcInsufficientResourcesNotifParams(displayed_in_notif)
	local params = {}
	local resource_names = {}
	for _, name in ipairs(displayed_in_notif) do
		resource_names[#resource_names + 1] = TLookupTag("<icon_" .. name .. ">")
	end
	params.low_on_resource_text = #resource_names == 1 and T(839, "Resource:") or T(840, "Resources:")
	params.resources = table.concat(resource_names, " ")
	params.rollover_title = T(5640, "Low Storage")
	params.rollover_text = T(10371, "Stored resources expected to last less than 3 Sols.")
	return params
end

GlobalVar("g_InsufficientMaintenanceResources", {})
GlobalGameTimeThread("InsufficientMaintenanceResourcesNotif", function()
	HandleNewObjsNotif(g_InsufficientMaintenanceResources, "InsufficientMaintenanceResources", nil, CalcInsufficientResourcesNotifParams, false, nil, true)
end)

function OnMsg.NewHour(hour)
	local maintenance_resources = UICity.maintenance_resources_consumed_yesterday
	local transportable_resources = {}
	GatherTransportableResources(transportable_resources)
	for k,v in pairs(maintenance_resources) do
		if v > 0 and (transportable_resources[k] / v) < const.MinDaysMaintenanceSupplyBeforeNotification then
			table.insert_unique(g_InsufficientMaintenanceResources, k)
		else
			table.remove_entry(g_InsufficientMaintenanceResources, k)
		end
	end
	-- food
	local consumed = ResourceOverviewObj:GetFoodConsumedByConsumptionYesterday()
	local data = ResourceOverviewObj.data and next(ResourceOverviewObj.data) and ResourceOverviewObj.data 
	if not data then
		data = {}
		GatherResourceOverviewData(data)	
	end	
	local food_total = data.Food
	if food_total>0 and consumed>0 and (food_total/consumed) < const.MinDaysFoodSupplyBeforeNotification then
		table.insert_unique(g_InsufficientMaintenanceResources, "Food")
	else
		table.remove_entry(g_InsufficientMaintenanceResources,"Food")		
	end
	
	-- water, power, oxygen
	local data = next(ResourceOverviewObj.data) and ResourceOverviewObj.data 
	if not data then
		data = {}
		GatherResourceOverviewData(data)	
	end	

	local water_stored = ResourceOverviewObj:GetTotalStoredWater()
	local air_stored = ResourceOverviewObj:GetTotalStoredAir()
	local el_stored = ResourceOverviewObj:GetTotalStoredPower()
    
	local ts_grid = UICity.ts_resources_grid
	local ts_grid_air,ts_grid_el,ts_grid_water = ts_grid.air,ts_grid.electricity,ts_grid.water
	local air_consumption   = ts_grid_air.consumption:GetLastValue()
	local air_production    = ts_grid_air.production:GetLastValue()
	local el_consumption    = ts_grid_el.consumption:GetLastValue()
	local el_production     = ts_grid_el.production:GetLastValue()
	local water_consumption = ts_grid_water.consumption:GetLastValue()
	local water_production  = ts_grid_water.production:GetLastValue()
	
	--water
	if const.MinHoursWaterResourceSupplyBeforeNotification*(water_consumption - water_production) > water_stored then
		table.insert_unique(g_InsufficientMaintenanceResources, "Water")
	else
		table.remove_entry(g_InsufficientMaintenanceResources,"Water")		
	end
   -- air
	if const.MinHoursAirResourceSupplyBeforeNotification*(air_consumption - air_production) > air_stored then
		table.insert_unique(g_InsufficientMaintenanceResources, "Air")
	else
		table.remove_entry(g_InsufficientMaintenanceResources,"Air")		
	end
   -- power
	if const.MinHoursPowerResourceSupplyBeforeNotification*(el_consumption - el_production) > el_stored then
		table.insert_unique(g_InsufficientMaintenanceResources, "Power")
	else
		table.remove_entry(g_InsufficientMaintenanceResources,"Power")		
	end
end

-------------------------------

DefineClass.CityObject = {
	__parents = { "Object", "Modifiable" },
	city = false,
}

function CityObject:Init()
	self.city = self.city or Cities[1]
end

function CityObject:Random(...)
	local city = self.city
	if not city then
		return AsyncRand(...)
	end
	return city:Random(...)
end

function CityObject:ChangeObjectModifier(modifier_table)
	local modifier = self:FindModifier(modifier_table.id, modifier_table.prop)
	local amount, percent = modifier_table.amount or 0, modifier_table.percent or 0
	if modifier then
		if amount~=0 or percent~=0 then
			modifier:Change(amount, percent, modifier_table.display_text)
		else
			modifier:delete()
		end
	elseif amount~=0 or percent~=0 then
		modifier_table.target = self
		ObjectModifier:new(modifier_table)
	end
end

function CityObject:RemoveObjectModifier(prop, id)
	local modifier = self:FindModifier(id, prop)
	if modifier then
		modifier:delete()
	end
end

function City:ForEachLabelObject(label, func, ...)
	if type(func) == "string" then
		for _, obj in ipairs(self.labels[label] or empty_table) do
			obj[func](obj, ...)
		end
	else
		for _, obj in ipairs(self.labels[label] or empty_table) do
			func(obj, ...)
		end
	end
end

local ts_capacity = 1024

DefineClass.TimeSeries = {
	__parents = { "InitDone" },
	data = false,
	next_index = 0, -- zero-based!
}

function TimeSeries:Init()
	self.data = {}
	for i = 1, ts_capacity do
		self.data[i] = false
	end
end

function TimeSeries:AddValue(value)
	local next_index = self.next_index
	self.data[next_index % ts_capacity + 1] = value
	self.next_index = next_index + 1
end

function TimeSeries:GetMaxOfLastValues(count)
	local data = self.data
	local index = self.next_index - 1
	local out_index = Min(count, ts_capacity, index + 1)
	local max_value
	while out_index > 0 do
		local value = data[index % ts_capacity + 1]
		if value then
			if not max_value then
				max_value = value
			elseif value > max_value then
				max_value = value
			end
		end
		out_index = out_index - 1
		index = index - 1
	end
	return max_value
end

-- n = -1 .. -ts_capacity
function TimeSeries:GetValue(n)
	return self.data[ (self.next_index + n + ts_capacity) % ts_capacity + 1 ] or 0
end

function TimeSeries:GetLastValue(default_value)
	local data = self.data
	local index = self.next_index - 1
	local min_value, max_value
	local value = data[index % ts_capacity + 1] or default_value or 0
	return value, min_value, max_value
end

function TimeSeries:GetLastValues(count, out_values, default_value)
	out_values = out_values or {}
	local data = self.data
	local index = self.next_index - 1
	local out_index = Min(count, ts_capacity, index + 1)
	for i = count, out_index+1, -1 do
		out_values[i] = default_value or 0
	end
	local min_value, max_value
	while out_index > 0 do
		local value = data[index % ts_capacity + 1]
		if value then
			if not min_value then
				min_value, max_value = value, value
			else
				if value < min_value then
					min_value = value
				else
					if value > max_value then
						max_value = value
					end
				end
			end
		end
		out_values[out_index] = value
		out_index = out_index - 1
		index = index - 1
	end
	return out_values, min_value, max_value
end

function City:InitTimeSeries()
	self.ts_colonists = TimeSeries:new()
	self.ts_colonists_unemployed = TimeSeries:new()
	self.ts_colonists_homeless = TimeSeries:new()
	self.ts_drones = TimeSeries:new()
	self.ts_shuttles = TimeSeries:new()
	self.ts_buildings = TimeSeries:new()
	self.ts_constructions_completed = TimeSeries:new()
	self.ts_resources = {}
	for _, resource in ipairs(StockpileResourceList) do
		self.ts_resources[resource] = {
			stockpile = TimeSeries:new(),
			produced = TimeSeries:new(),
			consumed = TimeSeries:new()
		}
	end
	self.ts_resources_grid = {}
	for _, resource in ipairs{"water", "air", "electricity"} do
		self.ts_resources_grid[resource] = {
			stored = TimeSeries:new(),
			production = TimeSeries:new(),
			consumption = TimeSeries:new(),
		}
	end
end

function SavegameFixups.CityTimeSeries()
	UICity:InitTimeSeries()
end

function City:CountBuildings(label)
	label = label or "Building"
	local all_buildings = 0
	for _, building in ipairs(self.labels[label] or empty_table) do
		if building.count_as_building and not building.destroyed and not IsKindOfClasses(building, "ConstructionSite", "ConstructionSiteWithHeightSurfaces") then
			all_buildings = all_buildings + 1
		end
	end
	return all_buildings
end

function City:CountShuttles()
	local shuttles = 0
	for _, hub in ipairs(self.labels.ShuttleHub or empty_table) do
		shuttles = shuttles + #hub.shuttle_infos
	end
	return shuttles
end

function City:UpdateTimeSeries()
	if self.day == 1 then return end

	self.ts_colonists:AddValue(#(self.labels.Colonist or empty_table))
	self.ts_colonists_unemployed:AddValue(#(self.labels.Unemployed or empty_table))
	self.ts_colonists_homeless:AddValue(#(self.labels.Homeless or empty_table))
	self.ts_drones:AddValue(#(self.labels.Drone or empty_table))

	self.ts_shuttles:AddValue(self:CountShuttles())
	self.ts_buildings:AddValue(self:CountBuildings())
	self.ts_constructions_completed:AddValue(self.constructions_completed_today)
	self.constructions_completed_today = 0

	local resource_overview_obj = ResourceOverviewObj
	for _, resource in ipairs(StockpileResourceList) do
		local ts_resource = self.ts_resources[resource]
		ts_resource.stockpile:AddValue(resource_overview_obj:GetAvailable(resource))
		ts_resource.produced:AddValue(resource_overview_obj:GetProducedYesterday(resource))
		ts_resource.consumed:AddValue(resource_overview_obj:GetConsumedByConsumptionYesterday(resource) + resource_overview_obj:GetConsumedByMaintenanceYesterday(resource))
	end
	local water, air, electricity = self.ts_resources_grid.water, self.ts_resources_grid.air, self.ts_resources_grid.electricity
	water.stored:AddValue(resource_overview_obj:GetTotalStoredWater())
	air.stored:AddValue(resource_overview_obj:GetTotalStoredAir())
	electricity.stored:AddValue(resource_overview_obj:GetTotalStoredPower())
    
	local data = resource_overview_obj.data
	if data.total_grid_samples > 0 then
		air.consumption:AddValue(data.total_air_consumption_sum / data.total_grid_samples)
		air.production:AddValue(data.total_air_production_sum / data.total_grid_samples)
		electricity.consumption:AddValue(data.total_power_consumption_sum / data.total_grid_samples)
		electricity.production:AddValue(data.total_power_production_sum / data.total_grid_samples)
		water.consumption:AddValue(data.total_water_consumption_sum / data.total_grid_samples)
		water.production:AddValue(data.total_water_production_sum / data.total_grid_samples)
		data.total_air_consumption_sum = 0
		data.total_air_production_sum = 0
		data.total_power_consumption_sum = 0
		data.total_power_production_sum = 0
		data.total_water_consumption_sum = 0
		data.total_water_production_sum = 0
		data.total_grid_samples = 0
	end
end

function City:GetAverageStat(stat)
	local list = self.labels.Colonist or empty_table
	local sum = 0
	for _, colonist in ipairs(list) do
		sum = sum + colonist:GetStat(stat)
	end
	return #list > 0 and (sum / #list) or 0
end

function OnMsg.ConstructionComplete(bld)
	UICity.constructions_completed_today = (UICity.constructions_completed_today or 0) + 1
end

-- desc - { ts1, ts2, scale = xxx }
-- day - current day number
-- n - number of values to return, pad with zeroes those not present in timeseries
-- height - max height in pixels permissible
-- axis_divisions - vertical axis will be divided in this many steps
-- returns array, axis_step
-- array contains one table per timeseries value, [1] and [2] come from ts1, [3] and [4] come from ts2 (nil if ts2 not given), [5] is day number
-- [1] and [3] are in pixels
-- axis_step is 1, 2 or 5 * 10^n, such as max value in relevant part of ts1/ts2 is less than axis_divisions * axis_step
function TimeSeries_GetGraphValueHeights(desc, day, n, height, axis_divisions)
	local values = {}
	local max = desc[1]:GetMaxOfLastValues(n)
	if desc[2] then
		max = Max(max, desc[2]:GetMaxOfLastValues(n))
	end
	local scale = desc.scale or 1
	local axis_step = scale
	while axis_step < 1000000000 do
		if not max or axis_divisions * axis_step > max then break end
		axis_step = 2 * axis_step
		if not max or axis_divisions * axis_step > max then break end
		axis_step = 5 * axis_step / 2
		if not max or axis_divisions * axis_step > max then break end
		axis_step = 2 * axis_step
	end
	local mul = height
	local div = axis_divisions * axis_step
	
	if day > n then
		for i = 1, n do
			local rel = i - n - 1
			local value1 = desc[1]:GetValue(rel)
			local value2 = desc[2] and desc[2]:GetValue(rel) or nil
			values[i] = {
				MulDivRound(value1, mul, div), 
				value1 / scale,
				value2 and MulDivRound(value2, mul, div) or nil,
				value2 and value2 / scale or nil,
				day + rel,
			}
		end
	else
		for i = 1, day - 1 do
			local rel = i - day
			local value1 = desc[1]:GetValue(rel)
			local value2 = desc[2] and desc[2]:GetValue(rel) or nil
			values[i] = {
				MulDivRound(value1, mul, div), 
				value1 / scale,
				value2 and MulDivRound(value2, mul, div) or nil,
				value2 and value2 / scale or nil,
				day + rel,
			}
		end
		for i = day, n do
			values[i] = {0,0,0,0,i}
		end
	end
	return values, axis_step / scale
end

function testquake()
    local q = Marsquake:new()
    q.Epicenter = "SolarPanel"
    q.Radius = 20
    q.TargetsCount = 10
    q:Execute()
end
