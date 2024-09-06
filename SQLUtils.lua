SQLUtils = {}

SQLUtils.DEBUG_LEVEL = 3 -- 0: announce, 1: errors, 2: warn, 3: info, 4: debug
function SQLUtils.debug(level, x, ...)
	if level <= SQLUtils.DEBUG_LEVEL then
		print("[SmartQuestLog]", x, ...)
	end
end

function SQLUtils.addAppendEntry(t, k, v)
	if t[k] == nil then
		t[k] = {}
	end
	table.insert(t[k], v)
end

function SQLUtils.addSumEntry(t, k, v)
	if t[k] == nil then
		t[k] = 0
	end
	t[k] = t[k] + v
end

function SQLUtils.count(T)
	local c = 0
	for _ in pairs(T) do c = c + 1 end
	return c
end

function SQLUtils.maxVal(T)
	local maxVal = 0
	local maxKey = nil
	
	for k, v in pairs(T) do
		if v > maxVal then
			maxVal = v
			maxKey = k
		end
	end
	
	return maxKey, maxVal
end

function SQLUtils.entryComparator(n, downwards)
	if n == 1 then
		if downwards then
			return function(a, b)
				return a[2] > b[2]
			end
		else
			return function(a, b)
				return a[2] < b[2]
			end
		end
	elseif n == 2 then
		if downwards then
			return function(a, b)
				if a[2] == b[2] then return a[3] > b[3] else return a[2] < b[2] end
			end
		else
			return function(a, b)
				if a[2] == b[2] then return a[3] < b[3] else return a[2] > b[2] end
			end
		end
	end
end

function SQLUtils.setTooltipPoint(questLogInterface)
	local x, y = questLogInterface.frame:GetCenter()
	if x < 750 then
		GameTooltip:SetPoint("TOPLEFT", questLogInterface.frame, "TOPRIGHT")
	else
		GameTooltip:SetPoint("TOPRIGHT", questLogInterface.frame, "TOPLEFT")
	end
end

function SQLUtils.xpPct(xp)
    return xp / UnitXPMax("player")
end

function SQLUtils.openQuestLog(questId)    
	local questLogIndex = GetQuestLogIndexByID(questId)
    if questLogIndex > 0 then		
		SelectQuestLogEntry(questLogIndex)
		ShowUIPanel(QuestLogFrame)
		QuestLog_UpdateQuestDetails()
		QuestLog_Update()	
	end
end

function SQLUtils.insertChatLink(chatLink)
	if ChatEdit_GetActiveWindow() then            
		ChatEdit_InsertLink(chatLink)
	end
end

function SQLUtils.getPlayerCoords()
    local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
	if not pos then return nil, nil end
	
	return pos.x * 100, pos.y * 100
end

function SQLUtils.playerDistanceToPoint(pointX, pointY)
	local playerX, playerY = SQLUtils.getPlayerCoords()
	if not playerX or not playerY then return nil end
	return math.sqrt((pointX - playerX)^2 + (pointY - playerY)^2)
end


function SQLUtils.isClassic()
	return WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end

function SQLUtils.isSoD()
	return SQLUtils.isClassic() and C_Seasons.HasActiveSeason() and C_Seasons.GetActiveSeason() == Enum.SeasonID.SeasonOfDiscovery
end
	
	