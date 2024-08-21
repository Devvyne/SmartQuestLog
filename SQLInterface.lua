SQLInterface = {}

QuestRecommenderFrame = nil
EventCatcher = nil
ShownZone = nil

local debug = SQLUtils.debug
local QuestState, QuestAgentType = SQLModel.QuestState, SQLModel.QuestAgentType
local AceGUI = LibStub("AceGUI-3.0")

-- Consts

local ObjectiveIcons = {
	monster = "Interface\\Addons\\Questie\\Icons\\slay.blp",
	item = "Interface\\Addons\\Questie\\Icons\\loot.blp",
	event = "Interface\\Addons\\Questie\\Icons\\event.blp",
    object = "Interface\\Addons\\Questie\\Icons\\object.blp",
}

local IndexToColor = {
	[0] = "FFC0C0C0", -- Gray
	[1] = "FF40C040", -- Green
	[2] = "FFFFFF00", -- Yellow
	[3] = "FFFF8040", -- Orange
	[4] = "FFFF1A1A", -- Red
}

function SQLInterface:Initialize()    
    self:BuildMainFrame()
	self:RegisterEvents()
	
	ShownZone = SQLModel:GetCurrentZoneId()	
	self:ReloadLog()	
end

function SQLInterface:RegisterEvents()
	
	EventCatcher = CreateFrame("Frame", "EventCatcher")
	
	local ReloadEvents = {	 -- (event name : should rebuild active quests log)
		QUEST_ACCEPTED = true,
		QUEST_TURNED_IN = true,
		QUEST_REMOVED = true,
		ZONE_CHANGED_NEW_AREA = false,
		PLAYER_LEVEL_UP = false,
		UI_INFO_MESSAGE = false,
	}	
	
	local EventHandler = function(self, event, ...)
		if ReloadEvents[event] ~= nil then			
			if event == "UI_INFO_MESSAGE" and arg[2] ~= "ERR_QUEST_OBJECTIVE_COMPLETE_S" then
				return
			end
			
			local shouldRebuildQuestLog = ReloadEvents[event]			
			debug(2, "Reloading log due to event ", event)
			SQLModel:Refresh()
			self:ReloadLog()
		else
			
		end
	end
	
	for e, _ in pairs(ReloadEvents) do
		EventCatcher:RegisterEvent(e)
	end	
	
	EventCatcher:SetScript("OnEvent", EventHandler)
end

function SQLInterface:BuildMainFrame()
    if not QuestRecommenderFrame then
        local recFrame = AceGUI:Create("Window")
        recFrame:SetCallback("OnClose", function()
            debug(0, "You can bring back the quest log with /sql")
        end)
        
        recFrame:SetLayout("List")
		recFrame:SetWidth(200)
		recFrame:SetHeight(400)
        recFrame:EnableResize(false)
		recFrame:SetPoint("LEFT", 0, 110)
		recFrame.frame:SetFrameStrata("LOW")
		-- recFrame.frame:SetResizeBounds(100, 400)
        
        QuestRecommenderFrame = recFrame
        -- table.insert(UISpecialFrames, "QuestRecommenderFrame")
    end
	return QuestRecommenderFrame
end

function SQLInterface:ReloadLog()
    QuestRecommenderFrame:Hide()
	QuestRecommenderFrame:ReleaseChildren()	
	
	QuestRecommenderFrame:SetTitle(SQLModel:GetZoneName(ShownZone))	
	
	local recommendedQuests, activeQuests, handInQuests = SQLModel:GetQuestsForZone(ShownZone)
	
	if #recommendedQuests > 0 then	
		local recommendedHeading = AceGUI:Create("Heading")
		recommendedHeading:SetText("Recommended")
		recommendedHeading:SetFullWidth(true)
		QuestRecommenderFrame:AddChild(recommendedHeading)
		
		local sortedRecommendedQuests = self:SortQuestsByEfficiency(recommendedQuests)
		for _, q in pairs(sortedRecommendedQuests) do		
			QuestRecommenderFrame:AddChild(SQLInterface:GetQuestLabel(q, QuestState.AVAILABLE))
		end
	end
	
	if #activeQuests > 0 then
		local activeHeading = AceGUI:Create("Heading")
		activeHeading:SetText("Active")
		activeHeading:SetFullWidth(true)
		QuestRecommenderFrame:AddChild(activeHeading)
		
		local sortedActiveQuests = self:SortQuestsByEfficiency(activeQuests)
		for _, q in pairs(sortedActiveQuests) do		
			QuestRecommenderFrame:AddChild(SQLInterface:GetQuestLabel(q, QuestState.ACTIVE_UNCOMPLETE))
		end
	end
	
	if #handInQuests > 0 then
		local handInHeading = AceGUI:Create("Heading")
		handInHeading:SetText("Hand In")
		handInHeading:SetFullWidth(true)
		QuestRecommenderFrame:AddChild(handInHeading)
		
		local sortedHandInQuests = self:SortQuestsByEfficiency(handInQuests)
		for _, q in pairs(sortedHandInQuests) do		
			QuestRecommenderFrame:AddChild(SQLInterface:GetQuestLabel(q, QuestState.ACTIVE_COMPLETE))
		end
	end
	
	local moreZones = SQLModel:GetMoreZones(ShownZone)
	local addedHeading = false
	for _, p in pairs(moreZones) do	
		if not addedHeading then
			local zonesHeading = AceGUI:Create("Heading")
			zonesHeading:SetText("More Zones")
			zonesHeading:SetFullWidth(true)
			QuestRecommenderFrame:AddChild(zonesHeading)
			addedHeading = true
		end
		
		QuestRecommenderFrame:AddChild(SQLInterface:GetZoneLabel(p[1]))
	end		
	
	if ShownZone ~= SQLModel:GetCurrentZoneId() then
		local backButton = AceGUI:Create("Button")
		backButton:SetText("Back")
		backButton:SetWidth(90)
		backButton:SetPoint("CENTER", QuestRecommenderFrame.frame, "CENTER")
		backButton:SetCallback("OnClick", function() SQLInterface:SwitchToZone(SQLModel:GetCurrentZoneId()) end)
		QuestRecommenderFrame:AddChild(backButton)
	end
	
	QuestRecommenderFrame:Show()
end


function SQLInterface:GetQuestLabel(questId, questState)
    ---@class AceInteractiveLabel
    local label = AceGUI:Create("InteractiveLabel")    
    label:SetFullWidth(true)
	
    label:SetText(SQLInterface:QuestText(questId, questState, true))   	
	
	local onClickFunc = function()
		-- Add the quest to the open chat window if it was a shift click
        if (IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow()) then            
			ChatEdit_InsertLink("[" .. SQLModel:QuestName(questId) .. " (" .. questId .. ")]")
        else
			SQLInterface:OpenQuestLog(questId)
		end
	end
	
	local onHoverStartFunc = function()
		SQLInterface:CreateQuestTooltip(questId, questState)
	end
	
	local onHoverEndFunc = function()
		if GameTooltip:IsShown() then GameTooltip:Hide() end
	end
	
    label:SetCallback("OnClick", onClickFunc)
    label:SetCallback("OnEnter", onHoverStartFunc)
    label:SetCallback("OnLeave", onHoverEndFunc)
	
    -- label:SetUserData('name', quest.name)
        -- ItemRefTooltip:SetHyperlink("%|Hquestie:" .. questId .. ":.*%|h", "%[%[" .. quest.level .. "%] " .. quest.name .. " %(" .. questId .. "%)%]")
    -- end)

    return label
end

function SQLInterface:CreateQuestTooltip(questId, questState)
    if GameTooltip:IsShown() then GameTooltip:Hide() end
    
	GameTooltip:SetOwner(QuestRecommenderFrame.frame, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", QuestRecommenderFrame.frame, "TOPRIGHT")
	GameTooltip:SetFrameStrata("TOOLTIP")
	
	GameTooltip:AddDoubleLine(SQLModel:QuestName(questId), questId)
	GameTooltip:AddDoubleLine("XP Reward", string.format("(%0.fxp) %0.f%%", SQLModel:QuestXp(questId), SQLModel:QuestRelativeXp(questId) * 100), 0.86, 0.86, 0.86, 0.86, 0.86, 0.86)
	GameTooltip:AddDoubleLine("Recommended Level", SQLModel:QuestLevel(questId), 0.86, 0.86, 0.86, 0.86, 0.86, 0.86)
	GameTooltip:AddDoubleLine("Quest Efficiency", string.format("%.2f", SQLModel:QuestEff(questId, true)), 0.86, 0.86, 0.86, 0.86, 0.86, 0.86)
	GameTooltip:AddLine(" ")
	
	if questState == QuestState.AVAILABLE then
		local starterId, starterType = SQLModel:GetQuestStarter(questId)		
		if starterId and starterType then			
			local starterName = SQLModel:GetAgentName(starterId, starterType)
			GameTooltip:AddLine(string.format("Started by %s (%s)", starterName, starterType))
			if starterType == QuestAgentType.ITEM then
				SQLInterface:InsertDroppersTooltip(SQLModel:GetZonesForAgent(starterId, QuestAgentType.ITEM)[ShownZone])				
			end
		end
	end
	
	if questState == QuestState.ACTIVE_COMPLETE then
		local finisherId, finisherType = SQLModel:GetQuestFinisher(questId)
		if finisherId and finisherType then
			local finisherName = SQLModel:GetAgentName(finisherId, finisherType)
			GameTooltip:AddLine(string.format("Hand in to %s (%s)", finisherName, finisherType))
		end
	end
	
	if questState == QuestState.ACTIVE_UNCOMPLETE then
		local objectives = C_QuestLog.GetQuestObjectives(questId)
		if next(objectives) then
			GameTooltip:AddLine("Objectives:")
			local objectiveIndex = 1
			for _, objective in pairs(objectives) do
				SQLInterface:InsertObjectiveTooltip(questId, objective, objectiveIndex)
				objectiveIndex = objectiveIndex + 1
			end
		end
	end
	
	GameTooltip:AddLine(" ")
	local chain = SQLModel:GetQuestChain(questId, true)
	if #chain > 1 then
		GameTooltip:AddLine("Chain:")
		local encounteredCurrentQuest = false
		local chainXp = 0
		for _, q in pairs(chain) do
			local prefix = ""
			if q == questId then
				encounteredCurrentQuest = true
				prefix = ">>> "
			end
			if encounteredCurrentQuest then
				chainXp = chainXp + SQLModel:QuestXp(q)
			end
			GameTooltip:AddLine(prefix .. SQLInterface:QuestText(q, SQLModel:GetQuestState(q), false))
		end		
		GameTooltip:AddDoubleLine("Incoming XP", string.format("(%dxp) %.0f%%", chainXp, chainXp / UnitXPMax("player") * 100), 0.86, 0.86, 0.86, 0.86, 0.86, 0.86)
	end
	
	GameTooltip:Show()

end

function SQLInterface:InsertObjectiveTooltip(questId, gameObjective, objectiveIndex)
	-- todo : add mark if objective is complete or in other zone
	local levelsStr = ""
	if gameObjective.type == 'monster' then	
		levelsStr = SQLInterface:NPCLevelsString(SQLModel:GetAgentsInZone(questId, objectiveIndex, ShownZone)[1][1])		
	end
	
	if ObjectiveIcons[gameObjective.type] then
		GameTooltip:AddDoubleLine(string.format("|T%s:14|t %s", ObjectiveIcons[gameObjective.type], gameObjective.text), levelsStr, 0.86, 0.86, 0.86, 0.86, 0.86, 0.86)
	else
		GameTooltip:AddDoubleLine(gameObjective.text, levelsStr, 0.86, 0.86, 0.86, 0.86, 0.86, 0.86)
	end
	
	if gameObjective.type == 'item' then		
		SQLInterface:InsertDroppersTooltip(SQLModel:GetAgentsInZone(questId, objectiveIndex, ShownZone))
	end		
end

function SQLInterface:InsertDroppersTooltip(droppers)
	if droppers ~= nil and #droppers > 0 then		
		local prefix = "Dropped by "
		if #droppers > 1 then
			GameTooltip:AddLine("Dropped by:")
			prefix = ""
		end
		
		local sortedDroppers = {}
		for _, p in pairs(droppers) do
			local dropperId, dropperType = p[1], p[2]
			local dropperName = prefix .. SQLModel:GetAgentName(dropperId, dropperType)
			local minLevel, maxLevel = 0, 0
			local levelsStr = ""
			if dropperType == QuestAgentType.NPC then
				minLevel, maxLevel = SQLModel:GetNPCLevels(dropperId)
				levelsStr = SQLInterface:NPCLevelsString(dropperId)
			end
			table.insert(sortedDroppers, {dropperName, dropperType, minLevel, levelsStr})
		end
		
		table.sort(sortedDroppers, SQLUtils.entryComparator(2, false))
		
		for _, p in pairs(sortedDroppers) do
			GameTooltip:AddDoubleLine(p[1], p[4], 0.86, 0.86, 0.86, 0.86, 0.86, 0.86)
		end
	end
end



function SQLInterface:NPCLevelsString(npcId)
	-- todo colorize
	local minLevel, maxLevel = SQLModel:GetNPCLevels(npcId)
	if minLevel and maxLevel then
		if minLevel == maxLevel then
			return string.format("l. %d", minLevel)
		else
			return string.format("l. %d-%d", minLevel, maxLevel)
		end
	end
	return ""
end

function SQLInterface:OpenQuestLog(questId)    
	local questLogIndex = GetQuestLogIndexByID(questId)
    if questLogIndex > 0 then		
		SelectQuestLogEntry(questLogIndex)
		ShowUIPanel(QuestLogFrame)
		QuestLog_UpdateQuestDetails()
		QuestLog_Update()	
	end
end

function SQLInterface:SwitchToZone(zoneId)
	if ShownZone ~= zoneId then	
		if GameTooltip:IsShown() then GameTooltip:Hide() end
		ShownZone = zoneId
		SQLInterface:ReloadLog()
	end
end

function SQLInterface:GetZoneLabel(zoneId)
	local label = AceGUI:Create("InteractiveLabel")    
    label:SetFullWidth(true)	
	
	local recommendedQuests, activeQuests, handInQuests = SQLModel:GetQuestsForZone(zoneId)
    
	local activeAbandonCount = 0
	for _, q in pairs(activeQuests) do
		if not SQLModel:IsQuestRecommended(q) then
			activeAbandonCount = activeAbandonCount + 1
		end
	end
	local activeCount = #activeQuests - activeAbandonCount
	
	local handInAbandonCount = 0
	for _, q in pairs(handInQuests) do
		if not SQLModel:IsQuestRecommended(q) then
			handInAbandonCount = handInAbandonCount + 1
		end
	end
	local handInCount = #handInQuests - handInAbandonCount
	local abandonCount = activeAbandonCount + handInAbandonCount
	
	-- todo use icons & only if above 0
	local questsCountsString = ""
	if #recommendedQuests > 0 then
		questsCountsString = questsCountsString .. " R" .. tostring(#recommendedQuests)
	end
	if activeCount > 0 then
		questsCountsString = questsCountsString .. " A" .. tostring(activeCount)
	end
	if handInCount > 0 then
		questsCountsString = questsCountsString .. " H" .. tostring(handInCount)
	end
	if abandonCount > 0 then
		questsCountsString = questsCountsString .. " X" .. tostring(abandonCount)
	end
	
	local zoneText = string.format("[%0.f°] %s %s", SQLModel:GetZoneEfficiency(zoneId) * 10, SQLModel:GetZoneName(zoneId), questsCountsString)
	label:SetText(zoneText)   	
	
	local onHoverStartFunc = function()
		SQLInterface:CreateZoneTooltip(zoneId)
	end
	
	local onHoverEndFunc = function()
		if GameTooltip:IsShown() then GameTooltip:Hide() end
	end
	
	label:SetCallback("OnClick", function() SQLInterface:SwitchToZone(zoneId) end)
    label:SetCallback("OnEnter", onHoverStartFunc)
    label:SetCallback("OnLeave", onHoverEndFunc)

    return label
end
	
function SQLInterface:CreateZoneTooltip(zoneId)
	if GameTooltip:IsShown() then GameTooltip:Hide() end
    
	GameTooltip:SetOwner(QuestRecommenderFrame.frame, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", QuestRecommenderFrame.frame, "TOPRIGHT")
	GameTooltip:SetFrameStrata("TOOLTIP")
	
	GameTooltip:AddLine(SQLModel:GetZoneName(zoneId))
	
	local recommendedQuests, activeQuests, handInQuests = SQLModel:GetQuestsForZone(zoneId)
	
	if #recommendedQuests > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Recommended:")
		
		local sortedRecommendedQuests = self:SortQuestsByEfficiency(recommendedQuests)
		for _, q in pairs(sortedRecommendedQuests) do		
			GameTooltip:AddLine(self:QuestText(q, QuestState.AVAILABLE, true))
		end
	end

	if #activeQuests > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Active:")
		
		local sortedActiveQuests = self:SortQuestsByEfficiency(activeQuests)
		for _, q in pairs(sortedActiveQuests) do		
			GameTooltip:AddLine(self:QuestText(q, QuestState.ACTIVE_UNCOMPLETE, true))
		end
	end
	
	if #handInQuests > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Hand In:")
		
		local sortedHandInQuests = self:SortQuestsByEfficiency(handInQuests)
		for _, q in pairs(sortedHandInQuests) do		
			GameTooltip:AddLine(self:QuestText(q, QuestState.ACTIVE_COMPLETE, true))
		end
	end
	
	GameTooltip:Show()
end


function SQLInterface:SortQuestsByEfficiency(quests)
    
	local tempSort = {}    

    for _, q in pairs(quests) do        
        local questDiffIndex = SQLModel:QuestDifficultyIndex(q)
        local questEff = SQLModel:QuestEff(q, true);
        
        table.insert(tempSort, { q, questDiffIndex or 0, questEff or 0 })
    end
    table.sort(tempSort, SQLUtils.entryComparator(2, true))

	local sortedQuestsByEff = {}
	for _, t in pairs(tempSort) do
		table.insert(sortedQuestsByEff, t[1])
	end

    return sortedQuestsByEff
end


function SQLInterface:QuestText(questId, questState, chain)		
	local questText = string.format(
		"[%0.f°] %s %s",
		SQLModel:QuestEff(questId, chain) * 10,
		SQLInterface:QuestTextMarker(questId, questState),
		SQLModel:QuestName(questId)
	)
	
	local colorStr = IndexToColor[SQLModel:QuestDifficultyIndex(questId)]			
	if colorStr then
		questText = "|c" .. colorStr .. questText .. "|r"
	end
	
	return questText	
end

function SQLInterface:QuestTextMarker(questId, questState)
	if (questState == QuestState.ACTIVE_UNCOMPLETE or questState == QuestState.ACTIVE_COMPLETE)
		and not SQLModel:IsQuestRecommended(questId) then
		
		return "|cFFFF1A1A(X)|r"
	end 
	return ""
end