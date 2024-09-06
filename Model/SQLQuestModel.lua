SQLQuestModel = {}


local debug = SQLUtils.debug
local QuestType, AgentType = SQLData.QuestType, SQLData.AgentType
local G_IsQuestDone, G_IsQuestComplete, G_GetQuestObjectives, G_GetQuestLogTitle = C_QuestLog.IsQuestFlaggedCompleted, IsQuestComplete, C_QuestLog.GetQuestObjectives, GetQuestLogTitle


-- STATE --

SQLQuestModel.ActiveQuests = nil
SQLQuestModel.RecommendedQuests = nil
SQLQuestModel.XpFactor = 1

function SQLQuestModel:Init()	
	self:BuildActiveQuestsMap() -- must be done before calc recommendations
	self:RefreshRecommendations()
end

function SQLQuestModel:RefreshXpFactor()
	local xpFactor = 1
	if SQLUtils.isSoD() then
		if UnitLevel("player") < 50 then
			xpFactor = 2.5
		else
			xpFactor = 1.5
		end
	end
	self.XpFactor = xpFactor
end

function SQLQuestModel:RefreshRecommendations()  -- active quests map must be updated before calling this
	debug(3, "Refreshing quest recommendations...")
	self.RecommendedQuests = {}
	
	for _, questId in pairs(SQLData.AllQuests) do
		local questState = SQLQuestModel.QuestState:StateForQuest(questId)
		if SQLQuestModel.QuestState:IsRelevantState(SQLQuestModel.QuestState:StateForQuest(questId)) then
			local quest = SQLQuestModel.Quest(questId)
			if quest:isRecommended() then			
				self.RecommendedQuests[questId] = quest
			end
		end
	end
end

function SQLQuestModel:BuildActiveQuestsMap()
	debug(3, "Analyzing active quests...")
	self.ActiveQuests = {}
	
	local i = 1
	while G_GetQuestLogTitle(i) do
		local _, _, _, _, _, _, _, questId = G_GetQuestLogTitle(i)
		SQLQuestModel:AddActiveQuest(questId)
		i = i + 1
	end
end

function SQLQuestModel:AddActiveQuest(questId)
	if self.ActiveQuests[questId] then debug(2, "Warning: quest", questId, "already in active quests map"); return end
	SQLQuestModel.ActiveQuests[questId] = SQLQuestModel.Quest(questId)
end

function SQLQuestModel:RemoveActiveQuest(questId)
	if not self.ActiveQuests[questId] then debug(2, "Warning: quest", questId, "not in active quests map"); return end
	SQLQuestModel.ActiveQuests[questId] = nil
end

-- OBJECTS --

-- Quest State --

SQLQuestModel.QuestState = {  -- DONT CHANGE ORDER (UI gets sorted by this)
	ACTIVE_UNCOMPLETE = 1,
	ACTIVE_COMPLETE = 2,
	AVAILABLE = 3,
	DONE = 4,
	UNAVAILABLE = 5,
	MISSING_PREQUEST = 6,
}
local QuestState = SQLQuestModel.QuestState

function QuestState:IsRelevantState(questState)
	return questState == QuestState.AVAILABLE or questState == QuestState.ACTIVE_UNCOMPLETE or questState == QuestState.ACTIVE_COMPLETE
end

function QuestState:StateForQuest(questId)
	if G_IsQuestDone(questId) then
		return QuestState.DONE
	end
	
	if SQLQuestModel.ActiveQuests[questId] then
		if G_IsQuestComplete(questId) then
			return QuestState.ACTIVE_COMPLETE
		end
		return QuestState.ACTIVE_UNCOMPLETE		
	end
	
	if SQLQuestModel:IsQuestUnavailable(questId) then
		return QuestState.UNAVAILABLE
	end

	return QuestState.AVAILABLE
end

function SQLQuestModel:IsQuestUnavailable(questId)	
	if SQLQuestieWrapper:IsPrequestMissing(questId) then
		return true
	end
	
	for _, q in pairs(SQLQuestieWrapper.ExclusiveQuests(questId)) do
		if G_IsQuestDone(q) then
			return true
		end
	end	-- TODO : Add reputation limitations
end

-- Quest Object --

function SQLQuestModel.Quest(questId)
	local name = SQLData:QuestName(questId)
	if not name then return nil end
	
	local type = SQLData:GetQuestType(questId)
	local requiredLevel = SQLData:RequiredQuestLevel(questId)
	local level = SQLData:QuestLevel(questId)
	local defaultZone = SQLData:QuestZone(questId)
	local objectives = SQLData:GetQuestObjectives(questId)
	
	local starterId, starterType = SQLData:GetQuestStarter(questId)
	local finisherId, finisherType = SQLData:GetQuestFinisher(questId)

	return {
		id = questId,
		type = type,
		name = name,
		requiredLevel = requiredLevel,
		level = level,
		defaultZone = defaultZone,
		objectives = objectives,
		start = {starterId, starterType},
		handIn = {finisherId, finisherType},
		xp = SQLQuestModel._Quest_Xp,	
		chainXp = SQLQuestModel._Quest_ChainXp,
		state = SQLQuestModel._Quest_State,
		chain = SQLQuestModel._Quest_Chain,
		eff = SQLQuestModel._Quest_Eff,
		effIndex = SQLQuestModel._Quest_EffIndex,
		gameObjectives = SQLQuestModel._Quest_GameObjectives,
		diffIndex = SQLQuestModel._Quest_DiffIndex,
		isRecommended = SQLQuestModel._Quest_IsRecommended,
		isFinished = SQLQuestModel._Quest_IsFinished,
	}
end

function SQLQuestModel._Quest_ChainXp(quest)
	return SQLData:ChainXp(quest.id)
end

function SQLQuestModel._Quest_Chain(quest, includePreQuests)
	local chain = {}
	for _, q in pairs(SQLData:GetQuestChain(quest.id, includePreQuests)) do
		table.insert(chain, SQLQuestModel.Quest(q))
	end
	return chain
end

function SQLQuestModel._Quest_State(quest)
	return SQLQuestModel.QuestState:StateForQuest(quest.id)
end

function SQLQuestModel._Quest_IsFinished(quest)
	return G_IsQuestDone(quest.id)
end

function SQLQuestModel._Quest_GameObjectives(quest)
	-- G_GetQuestObjectives(quest.id)
	return G_GetQuestObjectives(quest.id)
end

function SQLQuestModel._Quest_Eff(quest, calcChain)
	local playerLevel = UnitLevel("player")
	local effSum = 0
	local chain = { quest }
	if calcChain then chain = quest:chain(false) end
	
	for x, q in pairs(chain) do	
		local levelDiff = playerLevel - q.level
		local xpPct = SQLUtils.xpPct(q:xp())
		local effScore = xpPct * (1 + (levelDiff * 0.07))
		effSum = effSum + effScore
	end
	
	return ((effSum / #chain) * 0.4 + effSum * 0.6)   -- weighted avg of (avg of chain & sum of chain)
end

function SQLQuestModel._Quest_IsRecommended(quest)
	return SQLModel:IsQuestRecommended(quest, false)
end

function SQLQuestModel._Quest_EffIndex(quest, calcChain)
	return SQLModel:QuestEffIndex(quest, calcChain)
end

function SQLQuestModel._Quest_DiffIndex(quest)
	local levelDiff = quest.level - UnitLevel("player")

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

function SQLQuestModel._Quest_Xp(quest)
	return SQLQuestModel:QuestXp(quest.id)
end

local function roundByResolution(num, res)
	return res * floor((num + floor(res / 2)) / res)
end

function SQLQuestModel:QuestXp(questId)
	local xp = SQLData:QuestRawXp(questId)
	local playerLevel = UnitLevel("player")
	local levelDiff = SQLData:QuestLevel(questId) - playerLevel
	
	-- Gray quests xp reduction (we reduce 20% for each level beyond 5 levels below char level, until a minimum of 10%)
	if levelDiff < -5 then
		local levelsBelowThreshold = (levelDiff + 5)*(-1)
		local reduceFactor = 1 - (levelsBelowThreshold * 0.2)
		if reduceFactor < 0.1 then reduceFactor = 0.1 end
		xp = xp * reduceFactor
	end
	
	-- We then round down/up to nearest interval (intervals are 5/10/25/50 depending on xp magnitude)
	if (xp <= 100) then
        xp = roundByResolution(xp, 5)
    elseif (xp <= 500) then
		xp = roundByResolution(xp, 10)
    elseif (xp <= 1000) then
        xp = roundByResolution(xp, 25)
    else
        xp = roundByResolution(xp, 50)
    end
	
	-- SoD Discoverer's Delight
	xp = xp * self.XpFactor
	
	return xp
end
