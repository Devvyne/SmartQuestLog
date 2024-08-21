SQLModel = {}

local debug = SQLUtils.debug

SQLModel.QuestState = { 
	AVAILABLE = 1,
	ACTIVE_UNCOMPLETE = 2,
	ACTIVE_COMPLETE = 3,
	DONE = 4,
	UNAVAILABLE = 5,
	MISSING_PREQUEST = 6,
}

SQLModel.QuestType = {
	REGULAR = 1,
	REPEATABLE = 2,
	EVENT = 3,
	NA = 4,
}

SQLModel.QuestAgentType = {
	NPC = "NPC",
	GAME_OBJECT = "Game object",
	ITEM = "Item",
	EVENT = "Event",
	VENDOR = "Vendor",
}

local QuestState, QuestType, QuestAgentType = SQLModel.QuestState, SQLModel.QuestType, SQLModel.QuestAgentType

local ZoneMap = {}
local CompletedQuests = {}
local ChainQuestsMap = {}
local ActiveQuestsMap = {}

function SQLModel:Load()
	ZoneMap = self:GetZoneMap()
	ChainQuestsMap = SQLModelBuilder:BuildChainQuestsMap()
	self.Refresh()
end

function SQLModel:Refresh()
	
	-- Refresh completed quests cache
	CompletedQuests = GetQuestsCompleted()
	
	-- Refresh quest log cache	
	ActiveQuestsMap = SQLModelBuilder:BuildActiveQuestsMap()	
end

-- -- -- -- -- --
-- Zone Logics --
-- -- -- -- -- --

function SQLModel:GetQuestsForZone(zoneId)
	local recommendedQuests = {}
	local activeQuests = {}
	local handInQuests = {}
	
	local questsInZone = ZoneMap[zoneId]	
	if questsInZone then
		for q, _ in pairs(questsInZone) do		
			if self:GetQuestType(q) == QuestType.REGULAR then
				-- local questState = self:GetQuestState(q)
				-- if questState == QuestState.ACTIVE_UNCOMPLETE then 
					-- table.insert(activeQuests, q)
				-- elseif questState == QuestState.ACTIVE_COMPLETE then
					-- table.insert(handInQuests, q)
				if self:GetQuestState(q) == QuestState.AVAILABLE and self:IsQuestRecommended(q) then
					table.insert(recommendedQuests, q)
				end
			end
		end
    end
	
	for q, _ in pairs(ActiveQuestsMap) do
		if q > 0 then
			local questZones = SQLModel:GetZonesForActiveQuest(q, true)
			if questZones[zoneId] ~= nil then
				if IsQuestComplete(q) then
					table.insert(handInQuests, q)
				else
					table.insert(activeQuests, q)
				end
			end
		end
	end				
	
	return recommendedQuests, activeQuests, handInQuests

end

function SQLModel:GetMoreZones(shownZone)
	local zones = {}
	local recommendedZones = SQLModel:GetRecommendedZones() -- Must be sorted by efficiency!
	local activeZones = SQLModel:GetActiveZones()
	
	for z, eff in pairs(activeZones) do
		if z ~= shownZone then
			table.insert(zones, { z, eff })
		end
	end
	
	local maxZones = 5
	local zoneCount = #zones
	local recommendedIndex = 1
	while zoneCount <= maxZones and recommendedIndex <= #recommendedZones do
		local p = recommendedZones[recommendedIndex]
		local z, eff = p[1], p[2]
		
		if eff < 1 then break end -- We don't want to recommend zones below 10 eff		
		
		if activeZones[z] == nil and z ~= shownZone then
			table.insert(zones, { z, eff })
			zoneCount = zoneCount + 1
		end
		recommendedIndex = recommendedIndex + 1
	end
	
	table.sort(zones, SQLUtils.entryComparator(1, true))
	return zones	
end

function SQLModel:GetActiveZones()
	local activeZones = {}
	for q, _ in pairs(ActiveQuestsMap) do
		if q > 0 then
			local questZones = SQLModel:GetZonesForActiveQuest(q, false)
			for z, _ in pairs(questZones) do
				activeZones[z] = SQLModel:GetZoneEfficiency(z)
			end			
		end
	end
	return activeZones
end

function SQLModel:GetRecommendedZones()
	local recommendedZones = {}
	
	for zoneId, _ in pairs(ZoneMap) do	
		if zoneId > 0 then -- todo : handle professions etc...
			table.insert(recommendedZones, { zoneId, SQLModel:GetZoneEfficiency(zoneId) })
		end
    end
		
	table.sort(recommendedZones, SQLUtils.entryComparator(1, true))
	return recommendedZones
end	

function SQLModel:GetZoneEfficiency(zoneId)
	local recommendedQuests, activeQuests, handInQuests = SQLModel:GetQuestsForZone(zoneId)	
	local totalZoneEfficiency = 0
	
	for _, q in pairs(recommendedQuests) do		
		totalZoneEfficiency = totalZoneEfficiency + self:QuestEff(q, true)
	end
	
	for _, q in pairs(activeQuests) do
		if SQLModel:IsQuestRecommended(q) then			
			totalZoneEfficiency = totalZoneEfficiency + self:QuestEff(q, true)
		end
	end
	
	for _, q in pairs(handInQuests) do
		if SQLModel:IsQuestRecommended(q) then			
			totalZoneEfficiency = totalZoneEfficiency + self:QuestEff(q, true)
		end
	end
	
	return totalZoneEfficiency
end

function SQLModel:GetZonesForActiveQuest(questId, includeWeakZones)
	local objectives = ActiveQuestsMap[questId]
	local zones = {}
	local finisherZones = {}
	local isError = false
	local foundWeakZone = false
	local foundStrongZone = false
	
	if objectives and #objectives > 0 then
		finisherZones = objectives[#objectives] -- we keep hand in as the last objective		
		
		if IsQuestComplete(questId) then
			if next(finisherZones) then
				zones = finisherZones
				foundStrongZone = true
			end
		else			
			local objectiveIndex = 1
			for _, gameObjective in pairs(C_QuestLog.GetQuestObjectives(questId)) do
				if not gameObjective.finished then					
					local objectiveZones = objectives[objectiveIndex]
					local objectiveZonesNum = SQLUtils.count(objectiveZones)
					if objectiveZones then
						if objectiveZonesNum == 1 then
							local z, _ = next(objectiveZones)
							zones[z] = true
							foundStrongZone = true
						elseif objectiveZonesNum > 1 then
							if includeWeakZones then
								for z, _ in pairs(objectiveZones) do
									zones[z] = true								
								end
							else
								foundWeakZone = true
								debug(2, "Skipping", questId, "objective", objectiveIndex, "due to multiple zones")
							end
						else
							debug(1, "Error: no objectives in ActiveQuestsMap for quest id", questId)
							isError = true
							break
						end
					else
						debug(1, "Error: mismatching objective", objectiveIndex, "in ActiveQuestsMap, questId -", questId)
						isError = true
						break
					end
				end
				objectiveIndex = objectiveIndex + 1
			end			
		end
	else
		debug(1, "Error: quest id", questId, "not in ActiveQuestsMap")
		isError = true
	end
	
	if next(zones) and not isError then		
		return zones
	end
	
	-- Fallbacks
	if foundWeakZone and not foundStrongZone then
		debug(2, "Only weak zones for quest id", questId, "- using fallback zones")
	else
		debug(2, "No objectives zones for quest", questId, "- using fallback zones")
	end
	
	local questieZone = SQLModel:QuestZone(questId)
	if questieZone then
		debug(2, "Marking quest", questId, "with Questie fallback zone", questieZone)
		return { [ questieZone ] = true }
	end
	
	local starterId, starterType = SQLModel:GetQuestStarter(questId)
	if starterId and starterType then
		local starterZones = SQLModel:GetZonesForAgent(starterId, starterType)
		if starterZones and next(starterZones) then
			debug(2, "Marking quest", questId, "with Starter fallback zone", next(starterZones)[1])			
			return starterZones
		end
	end
	
	if next(finisherZones) then
		debug(2, "Marking quest", questId, "with Finisher fallback zone", next(finisherZones)[1])					
		return finisherZones
	end
	
	debug(2, "Marking quest", questId, "as Unknown Zone")
	return { [0] = true }
			
end


-- -- -- -- -- -- -- -- --
-- -- --  Quests  -- -- --
-- -- -- -- -- -- -- -- --

function SQLModel:GetAgentsInZone(questId, objectiveIndex, zoneId)
	return ActiveQuestsMap[questId][objectiveIndex][zoneId]
end

-- --   QUEST STATE  -- --

function SQLModel:IsQuestComplete(questId)
	return CompletedQuests[questId] ~= nil
end

function SQLModel:IsQuestActive(questId)
	return ActiveQuestsMap[questId] ~= nil
end

function SQLModel:IsQuestBlocked(questId)  -- Is quest unavailable due to another quest blocking it
	local exclusiveQuests = SQLQuestieWrapper.ExclusiveQuests(questId)
	for _, q in pairs(exclusiveQuests) do
		if SQLModel:IsQuestComplete(q) then
			return true
		end
	end
	return false -- TODO : Add reputation limitations
end

function SQLModel:GetQuestState(questId)
	-- Quest done
	if SQLModel:IsQuestComplete(questId) then
		return QuestState.DONE
	end
	
	-- Quest active	
	if self:IsQuestActive(questId) then
		if IsQuestComplete(questId) then
			return QuestState.ACTIVE_COMPLETE
		end
		return QuestState.ACTIVE_UNCOMPLETE		
	end
	
	-- Prequest missing
	if SQLQuestieWrapper:IsPrequestMissing(questId) then
		return QuestState.MISSING_PREQUEST
	end
	
	-- Unavailable quests
	if SQLModel:IsQuestBlocked(questId) then
		return QuestState.UNAVAILABLE
	end
	
	return QuestState.AVAILABLE
end

-- --   CHAIN QUESTS   -- --

function SQLModel:GetQuestChain(questId, includePreQuests)
	local chain = { questId }	
	
	if includePreQuests then
		local preQuestId = SQLModel:PreQuestInChain(questId)
		while preQuestId do
			table.insert(chain, 1, preQuestId)
			isChain = true
			preQuestId = SQLModel:PreQuestInChain(preQuestId)
		end
	end
	
	local nextQuestId = SQLModel:NextQuestInChain(questId)
    while nextQuestId do
        table.insert(chain, nextQuestId)
		isChain = true
		nextQuestId = SQLModel:NextQuestInChain(nextQuestId)
    end
	
	return chain
end

function SQLModel:PreQuestInChain(questId)
	if not ChainQuestsMap[questId] then debug(1, "Error: quest missing in chain map", questId); return nil end
	return ChainQuestsMap[questId][1]
end

function SQLModel:NextQuestInChain(questId)
	if not ChainQuestsMap[questId] then debug(1, "Error: quest missing in chain map", questId); return nil end
	return ChainQuestsMap[questId][3]
end

-- --   QUESTS XP / EFFICIENCY   -- --

function SQLModel:QuestRelativeXp(questId)
    return SQLModel:QuestXp(questId) / UnitXPMax("player")
end

function SQLModel:ChainXp(questId)
	local chain = SQLModel:GetQuestChain(questId, false)
    local chainXp = 0
	
	for _, q in pairs(chain) do
		chain = chain + SQLModel:QuestXp(q)
	end
	
    return chainXp
end

function SQLModel:QuestEff(questId, calcChain)
    local playerLevel = UnitLevel("player")
	local effSum = 0
	local chain = { questId }
	if calcChain then chain = SQLModel:GetQuestChain(questId, false) end
	
	for _, q in pairs(chain) do	
		local level = SQLModel:QuestLevel(q);    
		local levelDiff = playerLevel - level
		local xpPct = SQLModel:QuestRelativeXp(q)
		local effScore = xpPct * (1 + (levelDiff * 0.07))
		effSum = effSum + effScore
	end
	
	return ((effSum / #chain) * 0.4 + effSum * 0.6)   -- weighted avg of (avg of chain & sum of chain)
end

function SQLModel:IsQuestRecommended(questId)

	-- if already complete we'll allow lower efficiency
	if SQLModel:GetQuestState(questId) == QuestState.ACTIVE_COMPLETE then
		return self:QuestEff(questId, true) > 0.1
	end

	-- Only green or yellow quests are recommended
	local diffIndex = self:QuestDifficultyIndex(questId)
	if diffIndex < 1 or diffIndex > 2 then 
		return false
	end
	
	return self:QuestEff(questId, true) > 0.2
end

function SQLModel:QuestDifficultyIndex(questId)    
    local levelDiff = SQLModel:QuestLevel(questId) - UnitLevel("player")

    if (levelDiff >= 5) then
        return 4  -- Red
    elseif (levelDiff >= 3) then
        return 3  -- Orange
    elseif (levelDiff >= -2) then
        return 2  -- Yellow
    elseif (-levelDiff <= GetQuestGreenRange("player")) then
        return 1  -- Green
    else
        return 0 -- Gray
    end
end







-- function SQLModel:AddActiveQuest(questId)
	-- local objectivesMap = SQLModelBuilder:BuildObjectiveMapForQuest(questId)
	-- ActiveQuestsMap[questId] = objectivesMap
-- end

-- function SQLModel:RemoveActiveQuest(questId)
	-- ActiveQuestsMap[questId] = nil
-- end


