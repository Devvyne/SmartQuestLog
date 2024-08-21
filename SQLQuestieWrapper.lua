SQLQuestieWrapper = {}

local debug = SQLUtils.debug
local QuestState, QuestType, QuestAgentType = SQLModel.QuestState, SQLModel.QuestType, SQLModel.QuestAgentType

local l10n = QuestieLoader:ImportModule("l10n")
local QuestXP = QuestieLoader:ImportModule("QuestXP")
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
local QuestieCorrections = QuestieLoader:ImportModule("QuestieCorrections")
local QuestiePlayer = QuestieLoader:ImportModule("QuestiePlayer")
local QuestieEvent = QuestieLoader:ImportModule("QuestieEvent")
local ZoneDB = QuestieLoader:ImportModule("ZoneDB")


-- -- -- -- -- -- -- --
-- -- -- Zones -- -- --
-- -- -- -- -- -- -- --


function SQLModel:GetZoneMap()
	return ZoneDB:GetZonesWithQuests(false)
end

function SQLModel:GetZoneName(id)
    local name = l10n("Unknown Zone")
    for category, data in pairs(l10n.zoneLookup) do
        if data[id] then
            name = l10n.zoneLookup[category][id]
            break
        end
    end
    return name
end

function SQLModel:GetCurrentZoneId()
    local uiMapId = C_Map.GetBestMapForUnit("player")
    if uiMapId then
        return ZoneDB:GetAreaIdByUiMapId(uiMapId)
    end

    return ZoneDB.instanceIdToUiMapId[select(8, GetInstanceInfo())]
end


-- -- -- -- -- -- -- -- --
-- -- --  Quests  -- -- --
-- -- -- -- -- -- -- -- --

function SQLModel:QuestXp(questId)    
    return QuestXP:GetQuestLogRewardXP(questId, true) -- this func already calculates Discoverer’s Delight
end

function SQLModel:QuestLevel(questId)
	local qLevel = QuestieDB.QueryQuestSingle(questId, "questLevel")
	if not qLevel or qLevel < 1 then qLevel = UnitLevel("player") end
	return qLevel
end

function SQLModel:QuestName(questId)
	return QuestieDB.QueryQuestSingle(questId, "name")
end

function SQLModel:QuestZone(questId)
	local zone = QuestieDB.QueryQuestSingle(questId, "zoneOrSort")
	if not zone or zone < 0 then zone = 0 end
	return zone
end

function SQLModel:RequiredQuestLevel(questId)
	local level = QuestieDB.QueryQuestSingle(questId, "requiredLevel")
	if not level then level = 0 end
	return level
end

function SQLModel:GetQuestType(questId)
	if QuestieCorrections.hiddenQuests[questId]
	or not QuestiePlayer.HasRequiredRace(QuestieDB.QueryQuestSingle(q, "requiredRaces")) 
	or not QuestiePlayer.HasRequiredClass(QuestieDB.QueryQuestSingle(q, "requiredClasses")) then
		return QuestType.NA
	elseif QuestieEvent:IsEventQuest(questId) then
		return QuestType.EVENT
	elseif QuestieDB.IsRepeatable(questId) then
		return QuestType.REPEATABLE
	else
		return QuestType.REGULAR
	end
end


-- -- -- -- -- -- -- -- --
-- --  Quest Agents  -- --
-- -- -- -- -- -- -- -- --


local AgentTypeToQuery = {
	[ QuestAgentType.NPC ] = function(x,y) return QuestieDB.QueryNPCSingle(x,y) end,
	[ QuestAgentType.VENDOR ] = function(x,y) return QuestieDB.QueryNPCSingle(x,y) end,
	[ QuestAgentType.GAME_OBJECT ] = function(x,y) return QuestieDB.QueryObjectSingle(x,y) end,
	[ QuestAgentType.ITEM ] =  function(x,y) return QuestieDB.QueryItemSingle(x,y) end,
}

-- returns: agentId, QuestAgentType
function SQLModel:GetQuestStarter(questId)
	local res = QuestieDB.QueryQuestSingle(questId, "startedBy")
	if res then
		local npc, gameObj, item = res[1], res[2], res[3]
		
		if npc and npc[1] then
			local npcId = npc[1]
			return npcId, QuestAgentType.NPC
		end
			
		if gameObj and gameObj[1] then		
			local gameObjId = gameObj[1]
			return gameObjId, QuestAgentType.GAME_OBJECT
		end
		
		if item and item[1] then
			local itemId = item[1]
			return itemId, QuestAgentType.ITEM
		end	
	end
	return nil, nil
end

-- returns: agentId, QuestAgentType
function SQLModel:GetQuestFinisher(questId)
	local res = QuestieDB.QueryQuestSingle(questId, "finishedBy")
	
	if res then
		local npc, gameObj = res[1], res[2]
		
		if npc and npc[1] then
			local npcId = npc[1]
			return npcId, QuestAgentType.NPC
		end
		
		if gameObj and gameObj[1] then
			local gameObjId = gameObj[1]
			return gameObjId, QuestAgentType.GAME_OBJECT
		end
	end
	return nil, nil
end

function SQLModel:GetQuestObjectives(questId)
	local objectives = {}
	local questieObjectives = QuestieDB.QueryQuestSingle(questId, "objectives")
	
	if questieObjectives then
		local slayObjectives = questieObjectives[1]		
		if slayObjectives then
			for _, slayObj in pairs(slayObjectives) do
				table.insert(objectives, { QuestAgentType.NPC, slayObj[1] })
			end
		end
		
		local objectObjectives = questieObjectives[2]
		if objectObjectives then
			for _, objectObj in pairs(objectObjectives) do
				table.insert(objectives, { QuestAgentType.GAME_OBJECT, objectObj[1] })
			end
		end
		
		local itemObjectives = questieObjectives[3]
		if itemObjectives then
			for _, itemObj in pairs(itemObjectives) do
				table.insert(objectives, { QuestAgentType.ITEM, itemObj[1] })
			end
		end
	end
	
	local triggerObjective = QuestieDB.QueryQuestSingle(questId, "triggerEnd")
	if triggerObjective and triggerObjective[2] then		 
		for z, _ in pairs(triggerObjective[2]) do
			table.insert(objectives, { QuestAgentType.EVENT, z })
		end
	end
	
	return objectives
end


function SQLModel:GetZonesForAgent(agentId, agentType)
	if agentType == QuestAgentType.EVENT then
		return { [agentId] = {agentId, agentType} }
	end
	
	if agentType == QuestAgentType.ITEM then	
		return SQLModel:GetZonesForItem(agentId)	
	end	
	
	local zones = {}
	local query = AgentTypeToQuery[agentType]		
		
	local spawns = query(agentId, "spawns")
	if spawns then
		for z, _ in pairs(spawns) do
			SQLUtils.addEntry(zones, z, {agentId, agentType})
		end
	end		
	
	-- fallback to questie zoneID if there are no spawns 
	if not next(zones) then
		local agentZone = query(agentId, "zoneID")
		if agentZone then
			SQLUtils.addEntry(zones, agentZone, {agentId, agentType})			
		end
	end
	
	return zones
end

function SQLModel:GetZonesForItem(itemId)	
	local LootType = {
		NPC = {"npcDrops", QuestAgentType.NPC},
		GAME_OBJECT = {"objectDrops", QuestAgentType.GAME_OBJECT},
		ITEM = {"itemDrops", QuestAgentType.ITEM},
		VENDOR = {"vendors", QuestAgentType.VENDOR},
	}
	
	local zones = {}
	local populateZonesForLootType = function(lootType)				
		if LootType[lootType] then
			local field, agentType = LootType[lootType][1], LootType[lootType][2]			
			local droppers =  QuestieDB.QueryItemSingle(itemId, field)
			if droppers then
				for _, dropperId in pairs(droppers) do
					for z, _ in pairs(SQLModel:GetZonesForAgent(dropperId, agentType)) do
						SQLUtils.addEntry(zones, z, {dropperId, agentType})						
					end
				end
			end
		end
		return zones
	end
	
	populateZonesForLootType("NPC")
	populateZonesForLootType("GAME_OBJECT")
	populateZonesForLootType("ITEM")
	populateZonesForLootType("VENDOR")
	
	return zones
end
	
function SQLModel:GetAgentName(agentId, agentType)
	return AgentTypeToQuery[agentType](agentId, "name")
end

function SQLModel:GetNPCLevels(npcId)
	return QuestieDB.QueryNPCSingle(npcId, 'minLevel'), QuestieDB.QueryNPCSingle(npcId, 'maxLevel')
end




--- --- --- --- --- --- ----
--- QUESTIE WRAPPER ONLY ---
--- --- --- --- --- --- ----


function SQLQuestieWrapper:_GetPreQuest(questId)
	local preQuestList = QuestieDB.QueryQuestSingle(questId, "preQuestSingle")
	if preQuestList then
		return preQuestList[1]
	end
	return nil
end

function SQLQuestieWrapper:_GetNextQuest(questId)
	return QuestieDB.QueryQuestSingle(questId, "nextQuestInChain")
end

function SQLQuestieWrapper:IsPrequestMissing(questId)
	local preQuest = QuestieDB.QueryQuestSingle(questId, "preQuestSingle")
	if preQuest and not QuestieDB:IsPreQuestSingleFulfilled(preQuest) then
		return true
	end
	
	local preGroup = QuestieDB.QueryQuestSingle(questId, "preQuestGroup")
	if preGroup and not QuestieDB:IsPreQuestGroupFulfilled(preQuestGroup) then
		return true
	end
	
	return false
end

function SQLQuestieWrapper:ExclusiveQuests(questId)
	local deactivatingQuests = {}

	local nextQuest = SQLQuestieWrapper:_GetNextQuest(questId)
	if nextQuest then
		table.insert(deactivatingQuests, nextQuest)
	end
	
	local exclusiveQuests = QuestieDB.QueryQuestSingle(questId, "exclusiveTo")
	if exclusiveQuests then
		for _, q in pairs(exclusiveQuests) do
			table.insert(deactivatingQuests, q)			
        end
    end

	local parentQuest = QuestieDB.QueryQuestSingle(questId, "parentQuest")
	if parentQuest then
		table.insert(deactivatingQuests, parentQuest)
	end
	
	return deactivatingQuests
end

function SQLQuestieWrapper:AllQuests()
	return (QuestieDB.QuestPointers or QuestieDB.questData)
end