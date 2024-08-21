SQLModelBuilder = {}

local debug = SQLUtils.debug
local QuestType = SQLModel.QuestType


function SQLModelBuilder:BuildActiveQuestsMap()
	debug(2, "Building active quests map")
	activeQuestsMap = {}
	
	local i = 1
	while GetQuestLogTitle(i) do
		local _, _, _, _, _, _, _, questId = GetQuestLogTitle(i)
		activeQuestsMap[questId] = self:BuildObjectiveMapForQuest(questId)	
		i = i + 1
	end
	
	return activeQuestsMap
end


function SQLModelBuilder:BuildObjectiveMapForQuest(questId)
	local objectives = SQLModel:GetQuestObjectives(questId)
	local objectivesWithZones = {}
	
	-- we put starter as objective 0
	local starterId, starterType = SQLModel:GetQuestStarter(questId)
	if starterId and starterType then
		local starterZones = SQLModel:GetZonesForAgent(starterId, starterType)
		objectivesWithZones[0] = starterZones
		for z, _ in pairs(starterZones) do
			debug(3, "Marking quest id", questId, "starter", finisherType, finisherId, "for zone", z)		
		end
	end
	
	for _, p in pairs(objectives) do
		local agentType, agentId = p[1], p[2]		
		local agentZones = SQLModel:GetZonesForAgent(agentId, agentType)
		table.insert(objectivesWithZones, agentZones)
		for z, _ in pairs(agentZones) do
			debug(3, "Marking quest id", questId, "objective", agentType, agentId, "for zone", z)		
		end
	end
	
	-- we put hand in as the last objective
	local finisherId, finisherType = SQLModel:GetQuestFinisher(questId)
	if finisherId and finisherType then
		local finisherZones = SQLModel:GetZonesForAgent(finisherId, finisherType)
		table.insert(objectivesWithZones, finisherZones)
		for z, _ in pairs(finisherZones) do
			debug(3, "Marking quest id", questId, "hand-in", finisherType, finisherId, "for zone", z)		
		end
	end
	
	return objectivesWithZones	
end


-- CHAIN MAP --

local function addQuestToChainMap(questId, preQuestId, nextQuestId, overridePre, overrideNext, chainMap)
	if not chainMap[questId] then
		chainMap[questId] = { preQuestId, overridePre, nextQuestId, overrideNext }
	else
		if chainMap[questId][1] == nil then
			chainMap[questId][1] = preQuestId
			chainMap[questId][2] = overridePre
		else
			if preQuestId ~= nil and preQuestId ~= chainMap[questId][1] then
				if overridePre > chainMap[questId][2] then
					chainMap[questId][1] = preQuestId
					chainMap[questId][2] = overridePre
				elseif overridePre == chainMap[questId][2] and overridePre == 1 then
					debug(1, "Error: prequest collision for quest", questId, "-", chainMap[questId][1], preQuestId)
				end
			end
		end
		
		if chainMap[questId][3] == nil then
			chainMap[questId][3] = nextQuestId
			chainMap[questId][4] = overrideNext
		else
			if nextQuestId ~= nil and nextQuestId ~= chainMap[questId][3] then
				if overrideNext > chainMap[questId][4] then
					chainMap[questId][3] = nextQuestId
					chainMap[questId][4] = overrideNext
				elseif overrideNext == chainMap[questId][4] and overrideNext == 1 then
					debug(1, "Error: nextquest collision for quest", questId, "-", chainMap[questId][3], nextQuestId)
				end
			end
		end
	end
end

local function isRelevantQuest(q)
	return (q ~= nil
		and q > 0
		and SQLModel:GetQuestType(q) == QuestType.REGULAR)
end

function SQLModelBuilder:BuildChainQuestsMap()
	debug(2, "Building chain quests map...")
	local chainMap = {}
	for q, _ in pairs(SQLQuestieWrapper:AllQuests()) do
	
		if isRelevantQuest(q) then			
			local preQuest = SQLQuestieWrapper:_GetPreQuest(q)
			local nextQuest = SQLQuestieWrapper:_GetNextQuest(q)
			
			if not isRelevantQuest(preQuest) then preQuest = nil end
			if not isRelevantQuest(nextQuest) then nextQuest = nil end			
			
			addQuestToChainMap(q, preQuest, nextQuest, 0, 1, chainMap)
			if preQuest then addQuestToChainMap(preQuest, nil, q, 0, 0, chainMap) end
			if nextQuest then addQuestToChainMap(nextQuest, q, nil, 1, 0, chainMap) end
		end
	end	
	return chainMap
end