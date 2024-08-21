SQLInterface = {}

QuestRecommenderFrame = nil

local debug = SQLUtils.debug
local AgentType, ActionType = SQLData.AgentType, SQLActionModel.ActionType
local AceGUI = LibStub("AceGUI-3.0")

-- Consts

local ActionIcons = {
	[ ActionType.SLAY ] = "Interface\\Addons\\Questie\\Icons\\slay.blp",
	[ ActionType.LOOT ] = "Interface\\Addons\\Questie\\Icons\\loot.blp",
	[ ActionType.EXPLORE ] = "Interface\\Addons\\Questie\\Icons\\event.blp",
    [ ActionType.INTERACT ] = "Interface\\Addons\\Questie\\Icons\\object.blp",
	[ ActionType.HAND_IN ] = "Interface\\Addons\\Questie\\Icons\\complete.blp",
	[ ActionType.START ] = "Interface\\Addons\\Questie\\Icons\\available.blp",
	[ ActionType.GAIN_REPUTATION ] = "Interface\\Addons\\Questie\\Icons\\reputation.blp",
	[ ActionType.ABANDON ] = "Interface\\Addons\\SmartQuestLog\\Interface\\Icons\\abandon.tga",
	finished = "Interface\\Addons\\Questie\\Icons\\checkmark.tga",
}

local RatingIcons = {
	[4] = "Interface\\Addons\\SmartQuestLog\\Interface\\Icons\\star_gold.tga",
	[3] = "Interface\\Addons\\SmartQuestLog\\Interface\\Icons\\star_silver.tga",
	[2] = "Interface\\Addons\\SmartQuestLog\\Interface\\Icons\\star_bronze.tga",
	[1] = "Interface\\Addons\\SmartQuestLog\\Interface\\Icons\\star_gray.tga",
}

local chainIcon = "Interface\\Addons\\Questie\\Icons\\nextquest.tga"

local RatingColors = {
	[4] = "ffffc400",  -- Gold
	[3] = "ffffffff",  -- Silver
	[2] = "ffffca80",  -- Bronze
	[1] = "FFC0C0C0",  -- Gray
}

local RatingTerms = {
	[4] = "High",  -- Gold
	[3] = "Medium",  -- Silver
	[2] = "Low",  -- Bronze
	[1] = "Avoid",  -- Gray
}

local function icon(iconPath, iconSize)
	if not iconSize then iconSize = 14 end
	return string.format("|T%s:%d|t ", iconPath, iconSize)
end

local function actionIcon(actionType)	
	return icon(ActionIcons[actionType])
end

local IndexToColor = {
	[0] = "FFC0C0C0", -- Gray
	[1] = "FF40C040", -- Green
	[2] = "FFFFFF00", -- Yellow
	[3] = "FFFF8040", -- Orange
	[4] = "FFFF1A1A", -- Red
}

local IndexToDesc = {
	[0] = "Trivial",
	[1] = "Easy",
	[2] = "Medium",
	[3] = "Hard",
	[4] = "Extreme",
}

local WHITE = 0.86
local OFFWHITE = 0.66
local GRAY = 0.4

local FONT = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 11

-- -- -- -- -- -- --
-- --   INIT   -- -- 
-- -- -- -- -- -- --


function SQLInterface:Init()    
    self:BuildMainFrame()	
end

function SQLInterface:BuildMainFrame()
    if not QuestRecommenderFrame then
        local recFrame = AceGUI:Create("Window")
        recFrame:SetCallback("OnClose", function()
            SQLController:ClickedExit()		
        end)
        
        recFrame:SetLayout("List")
		recFrame:SetWidth(200)
		recFrame:SetHeight(300)
        recFrame:EnableResize(false)
		-- recFrame:SetPoint("LEFT", 0, 110)
		recFrame:SetPoint("TOPRIGHT", 0, -180)
		recFrame.frame:SetFrameStrata("LOW")
		-- recFrame.frame:SetResizeBounds(200, 200, 200, 400)
        
        QuestRecommenderFrame = recFrame
        -- table.insert(UISpecialFrames, "QuestRecommenderFrame")
    end
	return QuestRecommenderFrame
end

function SQLInterface:UpdateActions(shownZoneName, shownZoneActions, otherZones)
	if GameTooltip:IsShown() then GameTooltip:Hide() end

    -- QuestRecommenderFrame:Hide()
	QuestRecommenderFrame:ReleaseChildren()	
	QuestRecommenderFrame:SetHeight(300)
	
	QuestRecommenderFrame:SetTitle(shownZoneName)
		
	local headingCount = 0
	local labelCount = 0
	
	if next(shownZoneActions) then
		for _, p in pairs(shownZoneActions) do
			local subzone, subzoneEff, subzoneActions = p[1], p[2], p[3]
			local subzoneHeading = AceGUI:Create("Heading")
			subzoneHeading:SetText(subzone)
			subzoneHeading:SetFullWidth(true)
			QuestRecommenderFrame:AddChild(subzoneHeading)
			headingCount = headingCount + 1
			
			for _, a in pairs(subzoneActions) do			
				QuestRecommenderFrame:AddChild(SQLInterface:GetActionLabel(a))
				labelCount = labelCount + 1
			end	
		end
	else
		local nothingLabel = AceGUI:Create("Label")    
		nothingLabel:SetFullWidth(true)
		nothingLabel.label:SetMaxLines(2)
		nothingLabel:SetText("Nothing to do here...\r\n ")
		QuestRecommenderFrame:AddChild(nothingLabel)
	end
	
	if next(otherZones) then
		local zonesHeading = AceGUI:Create("Heading")
		zonesHeading:SetText("More Zones")
		zonesHeading:SetFullWidth(true)
		QuestRecommenderFrame:AddChild(zonesHeading)
		headingCount = headingCount + 1
	
		for _, zoneTuple in pairs(otherZones) do	
			QuestRecommenderFrame:AddChild(SQLInterface:GetZoneLabel(zoneTuple))
			labelCount = labelCount + 1
		end		
	end
	
	if SQLController:ShouldDisplayBackButton() then		
		QuestRecommenderFrame:AddChild(SQLInterface:BackButton())
	end
	
	local listHeight = headingCount * 18 + labelCount * 12.7
	if listHeight > 255 then
		QuestRecommenderFrame:SetHeight(300 + (listHeight - 255))
	end
	
	QuestRecommenderFrame:Show()
end

-- -- -- -- -- -- -- --
-- -- LIST  ITEMS -- -- 
-- -- -- -- -- -- -- --

-- Action UI (Shown zone) --

function SQLInterface:GetActionLabel(action)
    ---@class AceInteractiveLabel
    local label = AceGUI:Create("InteractiveLabel")    
    label:SetFullWidth(true)
	label.label:SetMaxLines(1)
    label.label:SetFont(FONT, FONT_SIZE)
	label:SetText(SQLInterface:GetActionText(action))   	
	
	local onClickFunc = function()
		SQLController:ClickedAction(action)		
	end
	
	local onHoverStartFunc = function()		
		SQLInterface:CreateActionTooltip(action)
	end
	
	local onHoverEndFunc = function()
		if GameTooltip:IsShown() then GameTooltip:Hide() end
	end
	
    label:SetCallback("OnClick", onClickFunc)
    label:SetCallback("OnEnter", onHoverStartFunc)
    label:SetCallback("OnLeave", onHoverEndFunc)

    return label
end

function SQLInterface:GetActionText(action)
	local text = ""
	if action.type == ActionType.START or action.type == ActionType.HAND_IN or action.type == ActionType.ABANDON then
		text = action.quest.name
	else		
		text = action:objectiveText()
	end
	
	return actionIcon(action.type) .. text
end

-- More zones UI --

function SQLInterface:GetZoneLabel(zoneTuple)
	local zoneId, zoneEff, zoneActions = zoneTuple[1], zoneTuple[2], zoneTuple[3]
	local label = AceGUI:Create("InteractiveLabel")    
    label:SetFullWidth(true)	
	label.label:SetFont(FONT, FONT_SIZE)
	
	-- TODO: use icons & only if above 0
	local questsCountsString = ""
	-- if #(zoneActions.recommended) > 0 then
		-- questsCountsString = questsCountsString .. " R" .. tostring(#(zoneActions.recommended))
	-- end
	-- if #(zoneActions.active) > 0 then
		-- questsCountsString = questsCountsString .. " A" .. tostring(#(zoneActions.active))
	-- end
	-- if #(zoneActions.handIn) > 0 then
		-- questsCountsString = questsCountsString .. " H" .. tostring(#(zoneActions.handIn))
	-- end
	-- if #(zoneActions.abandon) > 0 then
		-- questsCountsString = questsCountsString .. " X" .. tostring(#(zoneActions.abandon))
	-- end
	
	local zoneText = string.format("%s [%0.f°] %s %s", icon(RatingIcons[SQLModel:ZoneRecommendability(zoneEff)]), zoneEff * 10, SQLData:GetZoneName(zoneId), questsCountsString)
	label:SetText(zoneText)   	
	
	local onHoverStartFunc = function()
		SQLInterface:CreateZoneTooltip(zoneId, zoneEff, zoneActions)
	end
	
	local onHoverEndFunc = function()
		if GameTooltip:IsShown() then GameTooltip:Hide() end
	end
	
	label:SetCallback("OnClick", function() SQLController:ClickedZone(zoneId) end)
    label:SetCallback("OnEnter", onHoverStartFunc)
    label:SetCallback("OnLeave", onHoverEndFunc)

    return label
end

function SQLInterface:BackButton()
	local backButton = AceGUI:Create("Button")
	backButton:SetText("Back")
	backButton:SetWidth(90)
	backButton:SetPoint("CENTER", QuestRecommenderFrame.frame, "CENTER")
	backButton:SetCallback("OnClick", function() SQLController:ClickedBack() end)
	return backButton
end

-- -- -- -- -- -- --
-- -- TOOLTIPS -- -- 
-- -- -- -- -- -- --

-- Action tooltip --

function SQLInterface:CreateActionTooltip(action)
	local quest = action.quest
	local questXp = quest:xp()
	local questDiffIndex = quest:diffIndex()
	local questEff = quest:eff(true)
	local questRecommendability = quest:effIndex(true)

    if GameTooltip:IsShown() then GameTooltip:Hide() end
    GameTooltip:ClearLines()
	
	GameTooltip:SetOwner(QuestRecommenderFrame.frame, "ANCHOR_NONE")
	SQLUtils.setTooltipPoint(QuestRecommenderFrame)
	GameTooltip:SetFrameStrata("TOOLTIP")
	
	GameTooltip:AddDoubleLine(quest.name, icon(RatingIcons[questRecommendability]))
	
	local diffStr = string.format("|c%s%s (%d)|r", IndexToColor[questDiffIndex], IndexToDesc[questDiffIndex], quest.level)
	GameTooltip:AddDoubleLine("Difficulty", diffStr, WHITE, WHITE, WHITE)
		
	local recStr = string.format("|c%s%s (%.2f)|r", RatingColors[questRecommendability], RatingTerms[questRecommendability], questEff)
	GameTooltip:AddDoubleLine("XP Reward", string.format("%0.fxp (%0.f%%)", questXp, SQLUtils.xpPct(questXp) * 100), WHITE, WHITE, WHITE, WHITE, WHITE, WHITE)
	GameTooltip:AddDoubleLine("Recommendability", recStr, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE)
	GameTooltip:AddLine(" ")
	
	SQLInterface:InsertActionImperativeToTooltip(action)
	
	GameTooltip:AddLine(" ")
	local chain = quest:chain(true)
	if #chain > 1 then
		GameTooltip:AddLine("Chain:")
		for _, q in pairs(chain) do
			local forceIcon = nil
			local forceColor = nil
			
			if q:isFinished() then
				forceIcon = actionIcon("finished")
				forceColor = "FF666666"
			elseif q.id == quest.id then
				forceIcon = icon(chainIcon)				
			end
			GameTooltip:AddLine(SQLInterface:QuestText(q, false, forceIcon, forceColor))
			-- GameTooltip:AddLine(prefix .. quest.name)
		end		
		
		local chainXp = quest:chainXp()
		GameTooltip:AddDoubleLine("Incoming XP", string.format("(%dxp) %.0f%%", chainXp, SQLUtils.xpPct(chainXp) * 100), WHITE, WHITE, WHITE, WHITE, WHITE, WHITE)
	end
	
	GameTooltip:Show()
end

function SQLInterface:InsertActionImperativeToTooltip(action)
	-- Determine imperative icon
	local icon = actionIcon(action.type)
	if action.type == ActionType.START or action.type == ActionType.HAND_IN then
		if action.agent.type == AgentType.GAME_OBJECT then
			icon = actionIcon(ActionType.INTERACT)
		elseif action.agent.type == AgentType.ITEM then
			icon = actionIcon(ActionType.LOOT)
		end
	end
	
	-- Imperative line
	if action.type == ActionType.ABANDON then
		GameTooltip:AddLine(icon .. "Abandon quest")
	elseif action.type == ActionType.HAND_IN then
		GameTooltip:AddLine("Hand in to " .. icon .. action.agent.name)
	elseif action.type == ActionType.START then
		GameTooltip:AddLine("Accept quest from " .. icon .. action.agent.name)
	elseif action.type == ActionType.SLAY then
		GameTooltip:AddLine("Objectives:")
		GameTooltip:AddDoubleLine(icon .. action:objectiveText(), SQLInterface:NPCLevelsString(action.agent), nil, nil, nil, WHITE, WHITE, WHITE)
	else
		GameTooltip:AddLine("Objectives:")
		GameTooltip:AddLine(icon .. action:objectiveText())
	end
	
	-- Droppers
	if action.agent and action.agent.type == AgentType.ITEM then
		SQLInterface:InsertDroppersTooltip(action.agent, action._currentlyUnderZone, action._currentlyUnderSubzone)		
	end
	
	-- Other quest objectives
	if ActionType:IsObjective(action.type) then
		for i, o in pairs(action.quest:gameObjectives()) do
			if i ~= action._objectiveIndex then
				local objIcon = actionIcon(ActionType:FromGameType(o.type))
				local color = OFFWHITE
				if o.finished then
					objIcon = actionIcon("finished")
					color = GRAY
				end
				GameTooltip:AddLine(objIcon .. o.text, color, color, color)
			end
		end
	end
end

function SQLInterface:InsertDroppersTooltip(item, zone, subzone)
	local droppers = item.droppers
	if droppers ~= nil and #droppers > 0 then
		local vendors = {}
		local sortedDroppers = {}
		for _, dropper in pairs(droppers) do
			if dropper:subzones(zone)[subzone] then
				if dropper.type == AgentType.VENDOR then
					vendors[dropper.id] = true
				end		
				table.insert(sortedDroppers, {dropper, dropper.type, dropper.minLevel})
			end
		end
		
		table.sort(sortedDroppers, SQLUtils.entryComparator(2, false))
		
		for _, p in pairs(sortedDroppers) do
			local dropper = p[1]
			if dropper.type == AgentType.NPC and vendors[dropper.id] then
				debug(4, "Skipped NPC dropper", dropper.name, "which was also written as Vendor")
			else
				local rhs = ""
				if dropper.type == AgentType.NPC then
					rhs = SQLInterface:NPCLevelsString(dropper)
				elseif dropper.type == AgentType.VENDOR then
					rhs = "(Vendor)"
				elseif dropper.type == AgentType.GAME_OBJECT then
					rhs = "(Interact)"
				end
				GameTooltip:AddDoubleLine(dropper.name, rhs, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE)
			end
		end
	else
		debug(2, "Warning: no droppers for item id", item.id, "[", item.name, "]")
	end
end

function SQLInterface:NPCLevelsString(npc)
	-- todo colorize
	local minLevel, maxLevel = npc.minLevel, npc.maxLevel
	if minLevel and maxLevel then
		if minLevel == maxLevel then
			return string.format("(%d)", minLevel)
		else
			return string.format("(%d-%d)", minLevel, maxLevel)
		end
	end
	return ""
end


-- Zone tooltip --

	
function SQLInterface:CreateZoneTooltip(zoneId, zoneEff, zoneActions)
	if GameTooltip:IsShown() then GameTooltip:Hide() end
    GameTooltip:ClearLines()
	
	GameTooltip:SetOwner(QuestRecommenderFrame.frame, "ANCHOR_NONE")
	SQLUtils.setTooltipPoint(QuestRecommenderFrame)
	GameTooltip:SetFrameStrata("TOOLTIP")
	
	GameTooltip:AddDoubleLine(SQLData:GetZoneName(zoneId), icon(RatingIcons[SQLModel:ZoneRecommendability(zoneEff)], 20)) 

	if next(zoneActions.active) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Active:")
		
		local lastQuestId = nil
		for i, a in pairs(zoneActions.active) do
			if a.quest.id ~= lastQuestId then
				GameTooltip:AddLine(self:QuestText(a.quest, true))
			end
			
			GameTooltip:AddLine("     " .. actionIcon(a.type) .. a:objectiveText(), OFFWHITE, OFFWHITE, OFFWHITE, true)
			lastQuestId = a.quest.id
		end
	end
	
	if next(zoneActions.handIn) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Hand In:")
		
		for _, a in pairs(zoneActions.handIn) do
			GameTooltip:AddLine(self:QuestText(a.quest, true))
		end
	end
	
	if next(zoneActions.recommended) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Recommended:")
		
		for _, a in pairs(zoneActions.recommended) do
			GameTooltip:AddLine(self:QuestText(a.quest, true))
		end
	end
	
	if next(zoneActions.abandon) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Abandon:")
		
		for _, a in pairs(zoneActions.abandon) do
			GameTooltip:AddLine(self:QuestText(a.quest, true))
		end
	end
	
	GameTooltip:Show()
end

function SQLInterface:QuestText(quest, chain, forceIcon, forceColor)
	local _icon = forceIcon
	if not _icon then _icon = icon(RatingIcons[quest:effIndex(chain)]) end
	local questText =  _icon .. quest.name
	
	local colorStr = nil
	if forceColor then
		colorStr = forceColor
	else
		colorStr = IndexToColor[quest:diffIndex()]			
	end
	
	if colorStr then
		questText = "|c" .. colorStr .. questText .. "|r"
	end
	
	return questText	
end



