SQLManager = {}

local debug = SQLUtils.debug

EventCatcherFrame = nil

local active = false

function SQLManager:Init()
	SQLModel:Init()
	SQLController:Init()
	self:RegisterEvents()
	active = true
end

function SQLManager:Pause()
	debug(0, "You can bring back the quest log with /sql")	
	active = false
end

function SQLManager:Resume()
	debug(0, "Resuming...")
	active = true
	
	SQLModel:RefreshAll()
	SQLController:Init()
end


function SQLManager:RegisterEvents()
	EventCatcherFrame = CreateFrame("Frame", "EventCatcher")
	
	local RefreshEvents = {	 
		-- QUEST_TURNED_IN = true,
		QUEST_ACCEPTED = true,
		QUEST_REMOVED = true,
		ZONE_CHANGED_NEW_AREA = true,
		PLAYER_LEVEL_UP = true,
		UI_INFO_MESSAGE = true,
		CHAT_MSG_SYSTEM = true,
		-- CHAT_MSG_COMBAT_FACTION_CHANGE = true,
	}	
	
	local InfoMessagesForRefresh = {
		ERR_QUEST_OBJECTIVE_COMPLETE_S = true,
        ERR_QUEST_UNKNOWN_COMPLETE = true,
        ERR_QUEST_ADD_KILL_SII = true,
        ERR_QUEST_ADD_FOUND_SII = true,
        ERR_QUEST_ADD_ITEM_SII = true,
        ERR_QUEST_ADD_PLAYER_KILL_SII = true,
        ERR_QUEST_FAILED_S = true,
		ERR_LEARN_RECIPE_S = true, -- for SoD runes
		ERR_LEARN_SPELL_S = true, -- for SoD runes
	}
	
	local DELAY = 0.3
	
	local EventHandler = function(self, event, arg1, arg2)
		if active and RefreshEvents[event] ~= nil then
			if event == "CHAT_MSG_SYSTEM" then
				if string.find(arg1, "You are now %a+ with") then
					debug(3, "Faction standing changed. Refreshing log...")
					C_Timer.After(DELAY, function()		 -- we do this in delay so game has time to update its inner complete status						
						SQLModel:ObjectiveChanged()  -- TODO fix this to reload available quests as well
						SQLController:ReloadLog()
					end)
				end
				return
			end
		
			if event == "UI_INFO_MESSAGE" then
				if InfoMessagesForRefresh[GetGameMessageInfo(arg1)] then
					debug(3, "Objective changed. Refreshing log...")
					C_Timer.After(DELAY, function()		 -- we do this in delay so game has time to update its inner complete status						
						SQLModel:ObjectiveChanged()
						SQLController:ReloadLog()
					end)
				end
				return
			end
			
			if event == "ZONE_CHANGED_NEW_AREA" then
				debug(3, "Entered new zone. Refreshing log...")
				C_Timer.After(DELAY, function()
					SQLController:SwitchToCurrentZone()
				end)
				return
			end
			
			if event == "QUEST_ACCEPTED" then
				debug(3, string.format("Accepted quest %s (%d). Refreshing log...", SQLData:QuestName(arg2), arg2))
				C_Timer.After(DELAY, function()		 -- we do this in delay so game has time to update its inner complete status
					SQLModel:QuestAccepted(arg2)
					SQLController:ReloadLog()
				end)
				return
			end
			
			if event == "QUEST_REMOVED" then
				debug(3, string.format("Removed quest %s (%d). Refreshing log...", SQLData:QuestName(arg1), arg1))
				C_Timer.After(DELAY, function()
					SQLModel:QuestRemoved(arg1)
					SQLController:ReloadLog()
				end)
				return
			end
			
			if event == "PLAYER_LEVEL_UP" then
				debug(3, "Player leveled up. Refreshing log...")
				C_Timer.After(DELAY, function()
					SQLModel:PlayerLevelUp()
					SQLController:ReloadLog()
				end)
				return
			end
			
			debug(2, "Warning: unhandled event", event) -- Shouldn't get here			
		end
	end
	
	for e, _ in pairs(RefreshEvents) do
		EventCatcher:RegisterEvent(e)
	end	
	
	EventCatcher:SetScript("OnEvent", EventHandler)
end