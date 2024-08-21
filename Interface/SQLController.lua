SQLController = {}

local debug = SQLUtils.debug
local ActionType = SQLActionModel.ActionType

SQLController.ShownZone = nil
local shownZoneActionsCache = nil
local otherZonesActionsCache = nil

function SQLController:Init()
	SQLInterface:Init()
	self:SwitchToCurrentZone()
end

function SQLController:ReloadLog()
	local shownZoneActions = {}  -- subzone : list of actions
	local otherZonesActions = {}  -- zone : list of actions
	
	for _, action in pairs(SQLModel.Actions) do
		local actionZones = action:zones()
		if actionZones[self.ShownZone] ~= nil then
			local subzone, _ = SQLUtils.maxVal(action:subzones(self.ShownZone))
			action._currentlyUnderZone = self.ShownZone
			action._currentlyUnderSubzone = subzone
			SQLUtils.addAppendEntry(shownZoneActions, subzone, action)
		elseif SQLUtils.count(actionZones) == 1 then
			local z, _ = next(actionZones)
			SQLUtils.addAppendEntry(otherZonesActions, z, action)
		else
			SQLUtils.addAppendEntry(otherZonesActions, 0, action)
		end			
	end
	
	shownZoneActionsCache = self._sortActionsTable(shownZoneActions, self._subzoneSorter)
	otherZonesActionsCache = self._sortActionsTable(otherZonesActions, self._zoneSorter)
	
	SQLInterface:UpdateActions(SQLData:GetZoneName(self.ShownZone),	shownZoneActionsCache, otherZonesActionsCache)
end

function SQLController:UpdateSubzonesOrder()
	
end
	

-- Responding to events

function SQLController:ShouldDisplayBackButton()
	return self.ShownZone ~= SQLData:GetCurrentZoneId()
end

function SQLController:SwitchToZone(zoneId)		
	if zoneId ~= self.ShownZone then
		debug(3, string.format("Showing zone %s (%d)", SQLData:GetZoneName(zoneId), zoneId))
		self.ShownZone = zoneId
		self:ReloadLog()
	end
end

function SQLController:SwitchToCurrentZone()
	SQLController:SwitchToZone(SQLData:GetCurrentZoneId())
end

function SQLController:ClickedAction(action)
	-- Add the quest to the open chat window if it was a shift click
	if IsModifiedClick("CHATLINK") then            
		SQLUtils.insertChatLink("[" .. action.quest.name .. " (" .. action.quest.id .. ")]")
	else
		SQLUtils.openQuestLog(action.quest.id)
	end
end

function SQLController:ClickedZone(zoneId)
	self:SwitchToZone(zoneId)
end

function SQLController:ClickedBack()
	self:SwitchToCurrentZone()
end

function SQLController:ClickedExit()
	SQLManager:Pause()
end

-- Aux methods

-- sort by type and by efficiency
function SQLController._subzoneSorter(sz, l)
	table.sort(l, function(a, b)
		if a.type == b.type then 
			return a.quest:eff(true) > b.quest:eff(true)
		end
		return a.type > b.type
	end)
	
	if SQLController.ShownZone == SQLData:GetCurrentZoneId() then
		local distanceToSubzone = nil
		local szX, szY = SQLData:SubzoneCenter(SQLController.ShownZone, sz)
		if szX and szY then
			distanceToSubzone = SQLUtils.playerDistanceToPoint(szX, szY)
		end
		if not distanceToSubzone then distanceToSubzone = 1999 end
		return l, -distanceToSubzone, true
	else	
		local eff = 0
		for _, a in pairs(l) do 
			if a.type ~= ActionType.ABANDON then
				eff = eff + a.quest:eff(true)
			end
		end
		return l, eff, true
	end
end

-- sort by effIndex, then diffIndex, ensure same quest actions are together
local function zoneQuestComparator(a, b)
	local aEffIdx, bEffIdx = a.quest:effIndex(true), b.quest:effIndex(true)
	local aDiff, bDiff = a.quest:diffIndex(), b.quest:diffIndex()
	local aEff, bEff = a.quest:eff(true), b.quest:eff(true)
	local aId, bId = a.quest.id, b.quest.id
	
	if aEffIdx == bEffIdx then
		if aDiff == bDiff then
			if aEff == bEff then
				return aId > bId
			end
			return aEff > bEff
		end
		return aDiff < bDiff
	end
	return aEffIdx > bEffIdx
end

-- group by state and by quest, sort by efficiency
function SQLController._zoneSorter(z, l)
	local eff = 0
	local newL = { active = {}, handIn = {}, recommended = {}, abandon = {} }
	
	-- note: we assume these are already grouped by quest
	for _, a in pairs(l) do	
		if a.type ~= ActionType.ABANDON then
			eff = eff + a.quest:eff(true)
		end
		
		if ActionType:IsObjective(a.type) then
			table.insert(newL.active, a)
		elseif a.type == ActionType.HAND_IN then
			table.insert(newL.handIn, a)
		elseif a.type == ActionType.START then
			table.insert(newL.recommended, a)
		elseif a.type == ActionType.ABANDON then
			table.insert(newL.abandon, a)
		else
			-- should never get here
			debug(2, "Warning: unknown action type", a.type, "for quest", a.quest.id)
		end
	end
	
	table.sort(newL.active, zoneQuestComparator)
	table.sort(newL.handIn, zoneQuestComparator)
	table.sort(newL.recommended, zoneQuestComparator)
	table.sort(newL.abandon, zoneQuestComparator)
	local shouldShowZone = #(newL.active) > 0 or #(newL.handIn) > 0 or #(newL.abandon) > 0 or SQLModel:IsZoneRecommended(eff)
	return newL, eff, shouldShowZone
end

function SQLController._sortActionsTable(T, internalSorter)
	local temp = {}
	local newT = {}
	
	for z, l in pairs(T) do
		local newL, sortBy, shouldShowZone = internalSorter(z, l)  -- first sort the actions lists themselves
		
		if shouldShowZone then
			table.insert(newT, { z, sortBy, newL })
		end
	end
	
	-- Sort (sub)zones
	table.sort(newT, SQLUtils.entryComparator(1, true))	
	
	return newT
end
