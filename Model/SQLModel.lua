SQLModel = {}

local debug = SQLUtils.debug

local QuestType, AgentType = SQLData.QuestType, SQLData.AgentType
local Agent, QuestState, Quest, ActionType, Action = SQLAgentModel.Agent, SQLQuestModel.QuestState, SQLQuestModel.Quest, SQLActionModel.ActionType, SQLActionModel.Action
local G_GetQuestLogTitle = GetQuestLogTitle


SQLModel.Actions = nil
SQLModel.EffFactor = 1

function SQLModel:Init()
	SQLData:Init()
	SQLModel:RefreshAll()
end

function SQLModel:RefreshAll()
	SQLQuestModel:RefreshXpFactor()
	self:RefreshEffFactor()
	
	SQLQuestModel:Init()
	self:RefreshActions()
end

function SQLModel:RefreshActions()
	debug(3, "Refreshing actions...")
	self.Actions = {}
	
	for _, q in pairs(SQLQuestModel.ActiveQuests) do
		for _, a in pairs(SQLModel:ActionsForQuest(q)) do
			table.insert(self.Actions, a)
		end
	end
	
	for _, q in pairs(SQLQuestModel.RecommendedQuests) do
		if q:state() == QuestState.AVAILABLE then
			for _, a in pairs(SQLModel:ActionsForQuest(q)) do
				table.insert(self.Actions, a)
			end
		end
	end
end

function SQLModel:RefreshEffFactor()
	local lvlFactor = 1
	local playerLevel = UnitLevel("player")
	
	if playerLevel < 10 then
		lvlFactor = 3
	elseif playerLevel < 20 then
		lvlFactor = 2
	elseif playerLevel < 30 then
		lvlFactor = 1.5
	elseif playerLevel < 40 then
		lvlFactor = 1.25
	elseif playerLevel < 50 then
		lvlFactor = 1.125
	end
	
	self.EffFactor = SQLQuestModel.XpFactor * lvlFactor
end

function SQLModel:ActionsForQuest(quest)
	local questState = quest:state()
		
	if questState == QuestState.ACTIVE_COMPLETE then
		return { SQLActionModel.Action(quest, SQLActionModel.ActionType.HAND_IN, nil) }
	end
	
	if questState == QuestState.ACTIVE_UNCOMPLETE then
		if not SQLModel:IsQuestRecommended(quest, true) then
			return { SQLActionModel.Action(quest, SQLActionModel.ActionType.ABANDON, nil) }
		end
		
		local objActions = {}
		for objectiveIndex, gameObjective in pairs(quest:gameObjectives()) do
			if not gameObjective.finished then	
				local objective = quest.objectives[objectiveIndex]
				if not objective then
					debug(1, "Error: mismatching game objective", objectiveIndex, "in questId ", quest.id)
					break
				else
					table.insert(objActions, SQLActionModel.Action(quest, SQLActionModel.ActionType:FromGameType(gameObjective.type), objectiveIndex))
				end
			end
		end
		return objActions
	end
	
	if questState == QuestState.AVAILABLE then
		return { SQLActionModel.Action(quest, SQLActionModel.ActionType.START, nil) }
	end
	
	-- debug(2, "Warning: asked for actions for quest id", questId, "that is neither recommended nor active")
	return {}	
end


-- Respond to events --

function SQLModel:ObjectiveChanged()
	self:RefreshActions()
end

function SQLModel:QuestAccepted(questId)	
	SQLQuestModel:AddActiveQuest(questId)
	self:RefreshActions()
end

function SQLModel:QuestRemoved(questId)
	SQLQuestModel:RemoveActiveQuest(questId)
	SQLQuestModel:RefreshRecommendations()
	self:RefreshActions()
end

function SQLModel:PlayerLevelUp()
	SQLQuestModel:RefreshXpFactor()
	self:RefreshEffFactor()
	SQLQuestModel:RefreshRecommendations()
	self:RefreshActions()
end


-- Recommendation bars

function SQLModel:IsQuestRecommended(quest, ignoreLevels)
	-- if already complete we'll allow lower efficiency
	if quest:state() == QuestState.ACTIVE_COMPLETE then
		return quest:eff(true) > 0.03 * self.EffFactor	
	end

	-- Only green or yellow quests are recommended
	if not ignoreLevels then
		local diffIndex = quest:diffIndex()
		if diffIndex < 1 or diffIndex > 2 then 
			return false
		end
	end
	
	return quest:eff(true) > 0.04 * self.EffFactor	
end

function SQLModel:QuestEffIndex(quest, calcChain)
	local eff = quest:eff(calcChain)
	
	if eff < 0.03 * self.EffFactor then       -- Avoid (Gray)
		return 1
	elseif eff < 0.05 * self.EffFactor then   -- Low (Bronze)
		return 2
	elseif eff < 0.1 * self.EffFactor then    -- Medium (Silver)
		return 3  
	else return 4 end        				  -- High (Gold)
	
	--[[
	if UnitLevel("player") < 25 then
		if eff < 0.15 then       -- Avoid (Gray)
			return 1
		elseif eff < 0.25 then   -- Low (Bronze)
			return 2
		elseif eff < 0.4 then    -- Medium (Silver)
			return 3  
		else return 4 end        -- High (Gold)
	else
		if eff < 0.075 then       -- Avoid (Gray)
			return 1
		elseif eff < 0.15 then   -- Low (Bronze)
			return 2
		elseif eff < 0.25 then    -- Medium (Silver)
			return 3  
		else return 4 end        -- High (Gold)
	end
	--]]
end

function SQLModel:IsZoneRecommended(eff)	
	return eff > 0.3 * self.EffFactor
end

function SQLModel:ZoneRecommendability(eff)
	if eff < 0.25 * self.EffFactor then
		return 1
	elseif eff < 0.45 * self.EffFactor then
		return 2
	elseif eff < 0.7 * self.EffFactor then
		return 3
	else return 4 end


	--[[
	if UnitLevel("player") < 25 then
		if eff < 1.2 then
			return 1
		elseif eff < 2 then
			return 2
		elseif eff < 3 then
			return 3
		else return 4 end
	else
		if eff < 0.7 then
			return 1
		elseif eff < 1.25 then
			return 2
		elseif eff < 1.8 then
			return 3
		else return 4 end
	end
	--]]
end