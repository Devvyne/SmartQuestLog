SQLActionModel = {}

local debug = SQLUtils.debug

-- Action Type --

SQLActionModel.ActionType = {  -- DONT CHANGE ORDER (UI gets sorted by this)
	START = 1,
	SLAY = 2,
	INTERACT = 3,
	LOOT = 4,
	EXPLORE = 5,
	GAIN_REPUTATION = 6,
	HAND_IN = 7,
	ABANDON = 8,
}
local ActionType = SQLActionModel.ActionType

local gameObjTypeToActionType = {
	monster = ActionType.SLAY,
	object = ActionType.INTERACT,
	item = ActionType.LOOT,
	event = ActionType.EXPLORE,
	reputation = ActionType.GAIN_REPUTATION,
}

function ActionType:IsObjective(actionType)
	return (actionType == ActionType.SLAY or actionType == ActionType.INTERACT
		 or actionType == ActionType.LOOT or actionType == ActionType.EXPLORE
		 or actionType == ActionType.GAIN_REPUTATION)
end

function ActionType:FromGameType(gameObjectiveType)
	return gameObjTypeToActionType[gameObjectiveType]
end

-- Action object --

function SQLActionModel.Action(questObject, actionType, objectiveIndex)
	if not actionType or not questObject then debug(1, "Error: attempted to create action with nil parameter") end
	
	local agentRaw, agentObj = nil, nil	
	if actionType == ActionType.START then
		agentRaw = questObject.start
	elseif actionType == ActionType.HAND_IN then
		agentRaw = questObject.handIn
	elseif actionType == ActionType.SLAY or actionType == ActionType.INTERACT or
		   actionType == ActionType.LOOT or actionType == ActionType.EXPLORE then		   
		agentRaw = questObject.objectives[objectiveIndex]
	end
	
	if agentRaw then agentObj = SQLAgentModel.Agent(agentRaw[1], agentRaw[2]) end
	
	return {
		quest = questObject,
		type = actionType,
		_objectiveIndex = objectiveIndex,
		agent = agentObj,
		zones = SQLActionModel._Action_Zones,
		subzones = SQLActionModel._Action_Subzones,
		objectiveText = SQLActionModel._Action_ObjectiveText,
	}
end

function SQLActionModel._Action_Zones(action)
	if action.type ~= ActionType.ABANDON and action.type ~= ActionType.GAIN_REPUTATION then
		local zones = action.agent:zones()
		if next(zones) then
			return zones
		end
	end
	
	return { [action.quest.defaultZone] = true }		
end

function SQLActionModel._Action_Subzones(action, parentZoneId)
	if action.type ~= ActionType.ABANDON and action.type ~= ActionType.GAIN_REPUTATION then
		local subzones = action.agent:subzones(parentZoneId)
		if next(subzones) then
			return subzones
		end
	end
	
	return { [SQLData:GetZoneName(parentZoneId)] = 1 }	
end

function SQLActionModel._Action_ObjectiveText(action)
	return action.quest:gameObjectives()[action._objectiveIndex].text
end
	