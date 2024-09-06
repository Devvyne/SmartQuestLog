
SmartQuestLog = LibStub("AceAddon-3.0"):NewAddon("SmartQuestLog", "AceConsole-3.0", "AceEvent-3.0")

local debug = SQLUtils.debug

local WAIT_FOR_QUESTIE_MAX_TRIES = 10
local WAIT_FOR_QUESTIE_TRY_INTERVAL = 3

SmartQuestLog.waitingForQuestie = true
local function StartAfterQuestie()
	if SmartQuestLog.waitingForQuestie and Questie.started then
		SmartQuestLog.waitingForQuestie = false
		debug(0, "Initializing SmartQuestLog...")
		SQLManager:Init()
		SmartQuestLog:RegisterChatCommand("sql", "SlashCommand")	
		SmartQuestLog:RegisterChatCommand("rui", "ReloadUI")	
		SmartQuestLog:RegisterChatCommand("sqlzone", "ForceZone")	
		debug(0, "Done! Ready to go...")
	end
end

function SmartQuestLog:OnInitialize()		
	if not SQLUtils.isClassic() then
		debug(0, "SmartQuestLog is intended for WoW Classic and may not work properly on this version")		
	end
	
	debug(0, "Waiting for Questie...")	
	
	if not Questie then
		debug(0, "No addon named Questie. SmartQuestLog can't work without it")
		return
	end
	
	local tries = 0
	while tries < WAIT_FOR_QUESTIE_MAX_TRIES do
		C_Timer.After(WAIT_FOR_QUESTIE_TRY_INTERVAL * tries, StartAfterQuestie)
		tries = tries + 1
	end
	C_Timer.After(WAIT_FOR_QUESTIE_MAX_TRIES * WAIT_FOR_QUESTIE_TRY_INTERVAL, function()
		if not Questie.started then
			debug(0, "Questie still haven't started... SmartQuestLog won't init")
		end
	end)
end	

-- function SmartQuestLog:OnEnable()
	-- Called when the addon is enabled
-- end

-- function SmartQuestLog:OnDisable()
	-- Called when the addon is disabled
-- end

function SmartQuestLog:SlashCommand(msg)
	SQLManager:Resume()
end

function SmartQuestLog:ReloadUI(msg)
	ReloadUI()
end

function SmartQuestLog:ForceZone(msg)
	SQLController:SwitchToZone(tonumber(msg))
end
