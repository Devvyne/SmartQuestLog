SQLQuestieWrapper = {}

local debug = SQLUtils.debug
local QuestType, AgentType = SQLData.QuestType, SQLData.AgentType

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


function SQLData:GetZoneName(id)
    local name = l10n("Unknown Zone")
    for category, data in pairs(l10n.zoneLookup) do
        if data[id] then
            name = l10n.zoneLookup[category][id]
            break
        end
    end
    return name
end

function SQLData:GetCurrentZoneId()
    local uiMapId = C_Map.GetBestMapForUnit("player")
    if uiMapId then
        return ZoneDB:GetAreaIdByUiMapId(uiMapId)
    end

    return ZoneDB.instanceIdToUiMapId[select(8, GetInstanceInfo())]
end

local function correctZone(zoneId)
	if ZoneDB.private.areaIdToUiMapId[zoneId] == nil then
		local correctZoneId = ZoneDB:GetParentZoneId(zoneId)
		debug(4, "Corrected zone", zoneId, "to parent zone", correctZoneId)
		return correctZoneId
	end
	return zoneId
end

-- -- -- -- -- -- -- -- --
-- -- --  Quests  -- -- --
-- -- -- -- -- -- -- -- --

function SQLData:QuestXp(questId)    
    return QuestXP:GetQuestLogRewardXP(questId, true) -- this func already calculates Discoverer’s Delight
end

function SQLData:QuestLevel(questId)
	local qLevel = QuestieDB.QueryQuestSingle(questId, "questLevel")
	if not qLevel or qLevel < 1 then return 0 end
	return qLevel
end

function SQLData:QuestName(questId)
	return QuestieDB.QueryQuestSingle(questId, "name")
end

function SQLData:QuestZone(questId)
	local zone = correctZone(QuestieDB.QueryQuestSingle(questId, "zoneOrSort"))
	if not zone or zone < 0 then zone = 0 end
	return zone
end

function SQLData:RequiredQuestLevel(questId)
	local level = QuestieDB.QueryQuestSingle(questId, "requiredLevel")
	if not level then level = 0 end
	return level
end

function SQLData:GetQuestType(questId)
	if QuestieCorrections.hiddenQuests[questId]
	or not QuestiePlayer.HasRequiredRace(QuestieDB.QueryQuestSingle(questId, "requiredRaces")) 
	or not QuestiePlayer.HasRequiredClass(QuestieDB.QueryQuestSingle(questId, "requiredClasses")) then
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
	[ AgentType.NPC ] = function(x,y) return QuestieDB.QueryNPCSingle(x,y) end,
	[ AgentType.VENDOR ] = function(x,y) return QuestieDB.QueryNPCSingle(x,y) end,
	[ AgentType.GAME_OBJECT ] = function(x,y) return QuestieDB.QueryObjectSingle(x,y) end,
	[ AgentType.ITEM ] =  function(x,y) return QuestieDB.QueryItemSingle(x,y) end,
}

-- returns: agentId, AgentType
function SQLData:GetQuestStarter(questId)
	local res = QuestieDB.QueryQuestSingle(questId, "startedBy")
	if res then
		local npc, gameObj, item = res[1], res[2], res[3]
		
		if item and item[1] then
			local itemId = item[1]
			return itemId, AgentType.ITEM
		end	
			
		if gameObj and gameObj[1] then		
			local gameObjId = gameObj[1]
			return gameObjId, AgentType.GAME_OBJECT
		end
		
		if npc and npc[1] then
			local npcId = npc[1]
			return npcId, AgentType.NPC
		end
	end
	return nil, nil
end

-- returns: agentId, AgentType
function SQLData:GetQuestFinisher(questId)
	local res = QuestieDB.QueryQuestSingle(questId, "finishedBy")
	
	if res then
		local npc, gameObj = res[1], res[2]
		
		if npc and npc[1] then
			local npcId = npc[1]
			return npcId, AgentType.NPC
		end
		
		if gameObj and gameObj[1] then
			local gameObjId = gameObj[1]
			return gameObjId, AgentType.GAME_OBJECT
		end
	end
	return nil, nil
end

function SQLData:GetQuestObjectives(questId)
	local objectives = {}
	local questieObjectives = QuestieDB.QueryQuestSingle(questId, "objectives")
	
	if questieObjectives then
		local slayObjectives = questieObjectives[1]		
		if slayObjectives then
			for _, slayObj in pairs(slayObjectives) do
				table.insert(objectives, { slayObj[1], AgentType.NPC })
			end
		end
		
		local objectObjectives = questieObjectives[2]
		if objectObjectives then
			for _, objectObj in pairs(objectObjectives) do
				table.insert(objectives, { objectObj[1], AgentType.GAME_OBJECT })
			end
		end
		
		local itemObjectives = questieObjectives[3]
		if itemObjectives then
			for _, itemObj in pairs(itemObjectives) do
				table.insert(objectives, { itemObj[1], AgentType.ITEM })
			end
		end
		
		local repObjective = questieObjectives[4]
		if repObjective then
			table.insert(objectives, { repObjective[1], AgentType.REPUTATION })
		end
		
		local spellObjectives = questieObjectives[6]
		if spellObjectives then
			for _, spellObj in pairs(spellObjectives) do
				table.insert(objectives, { spellObj[3], AgentType.RUNE })
			end
		end
	end
	
	local triggerObjective = QuestieDB.QueryQuestSingle(questId, "triggerEnd")
	if triggerObjective and triggerObjective[2] then		 
		for z, coords in pairs(triggerObjective[2]) do
			table.insert(objectives, { questId, AgentType.EVENT })
		end
	end
	
	return objectives
end


function SQLData:GetZonesForAgent(agentId, agentType)
	if agentType == AgentType.EVENT then
		return { [agentId[1]] = {{agentId, agentType, agentId[2]}} }
	end
	
	if agentType == AgentType.ITEM then	
		return SQLData:GetZonesForItem(agentId)	
	end	
	
	local zones = {}
	local query = AgentTypeToQuery[agentType]		
		
	local spawns = query(agentId, "spawns")
	if spawns then
		for z, spawnsInZone in pairs(spawns) do
			local agentZone = correctZone(z)
			if agentZone and agentZone > 0 then				
				SQLUtils.addAppendEntry(zones, agentZone, {agentId, agentType, spawnsInZone})
			end
		end
	end		
	
	-- fallback to questie zoneID if there are no spawns 
	if not next(zones) then
		local agentZone = query(agentId, "zoneID")
		agentZone = correctZone(agentZone)
		if agentZone and agentZone > 0 then
			SQLUtils.addAppendEntry(zones, agentZone, {agentId, agentType, {}})			
		end
	end
	
	return zones
end

function SQLData:GetZonesForItem(itemId)	
	local LootType = {
		NPC = {"npcDrops", AgentType.NPC},
		GAME_OBJECT = {"objectDrops", AgentType.GAME_OBJECT},
		ITEM = {"itemDrops", AgentType.ITEM},
		VENDOR = {"vendors", AgentType.VENDOR},
	}
	
	local zones = {}
	local populateZonesForLootType = function(lootType)				
		if LootType[lootType] then
			local field, agentType = LootType[lootType][1], LootType[lootType][2]			
			local droppers =  QuestieDB.QueryItemSingle(itemId, field)
			if droppers then
				for _, dropperId in pairs(droppers) do
					for z, l in pairs(SQLData:GetZonesForAgent(dropperId, agentType)) do
						for _, p in pairs(l) do							
							SQLUtils.addAppendEntry(zones, z, p)						
						end
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

------


function SQLData:GetAgentName(agentId, agentType)
	if agentType == AgentType.EVENT then
		local eventObj = QuestieDB.QueryQuestSingle(agentId, "triggerEnd")
		if eventObj and eventObj[1] then		 
			return eventObj[1]
		else
			return nil
		end
	end	
	return AgentTypeToQuery[agentType](agentId, "name")
end

function SQLData:GetAgentSpawns(agentId, agentType)
	if agentType == AgentType.ITEM then	
		return {} -- item has no spawns, only droppers
	end
	
	if agentType == AgentType.EVENT then
		local eventObj = QuestieDB.QueryQuestSingle(agentId, "triggerEnd")
		if eventObj and eventObj[2] then		 
			return eventObj[2]
		else
			debug(2, "Warning: no coords for trigger objective in quest", agentId)
			return {}
		end
	end	
	
	local spawns = AgentTypeToQuery[agentType](agentId, "spawns")
	if not spawns then
		debug(2, "Warning: no spawns for", agentType, agentId, "[", SQLData:GetAgentName(agentId, agentType), "]")
		return {}
	end
	return spawns
end

function SQLData:GetNPCLevels(npcId)
	return QuestieDB.QueryNPCSingle(npcId, 'minLevel'), QuestieDB.QueryNPCSingle(npcId, 'maxLevel')
end

function SQLData:GetItemDroppers(itemId)	
	local LootType = {
		NPC = {"npcDrops", AgentType.NPC},
		GAME_OBJECT = {"objectDrops", AgentType.GAME_OBJECT},
		ITEM = {"itemDrops", AgentType.ITEM},
		VENDOR = {"vendors", AgentType.VENDOR},
	}
	
	local allDroppers = {}
	local populateDroppersForLootType = function(lootType)				
		if LootType[lootType] then
			local field, agentType = LootType[lootType][1], LootType[lootType][2]			
			local droppers =  QuestieDB.QueryItemSingle(itemId, field)
			if droppers then
				for _, dropperId in pairs(droppers) do
					table.insert(allDroppers, { dropperId, agentType })
					-- for z, l in pairs(SQLData:GetZonesForAgent(dropperId, agentType)) do
						-- for _, p in pairs(l) do							
							-- SQLUtils.addAppendEntry(zones, z, p)						
						-- end
					-- end
				end
			end
		end		
	end
	
	populateDroppersForLootType("NPC")
	populateDroppersForLootType("GAME_OBJECT")
	populateDroppersForLootType("ITEM")
	populateDroppersForLootType("VENDOR")
	
	return allDroppers
end

--- --- --- --- --- --- ----
--- QUESTIE WRAPPER ONLY ---
--- --- --- --- --- --- ----


function SQLQuestieWrapper:_GetPreQuest(questId)
	local preQuestList = QuestieDB.QueryQuestSingle(questId, "preQuestSingle")
	if preQuestList and preQuestList[1] and preQuestList[1] > 0 then
		return preQuestList[1]
	end
	return nil
end

function SQLQuestieWrapper:_GetNextQuest(questId)
	local nextQuest = QuestieDB.QueryQuestSingle(questId, "nextQuestInChain")
	if not nextQuest or nextQuest <= 0 then return nil else return nextQuest end	
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
	local allQuests = {}
	for questId, _ in pairs(QuestieDB.QuestPointers) do
		if SQLData:GetQuestType(questId) == QuestType.REGULAR then
			table.insert(allQuests, questId)
		end
	end
	
	return allQuests
end