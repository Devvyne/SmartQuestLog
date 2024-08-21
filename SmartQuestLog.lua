
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
		SmartQuestLog:RegisterChatCommand("fonts", "Fonts")	
		debug(0, "Done! Ready to go...")
	end
end

function SmartQuestLog:OnInitialize()		
	if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
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






local AceGUI = LibStub("AceGUI-3.0")

local fonts = {
	{"GameFontNormal", GameFontNormal},
	{"GameFontNormalSmall", GameFontNormalSmall},
	-- GameFontNormalLarge = GameFontNormalLarge,
	{"GameFontHighlight", GameFontHighlight},
	{"GameFontHighlightSmall", GameFontHighlightSmall},
	{"GameFontHighlightSmallOutline", GameFontHighlightSmallOutline},
	-- GameFontHighlightLarge,
	{"GameFontDisable", GameFontDisable},
	{"GameFontDisableSmall", GameFontDisableSmall},
	{"GameFontDisableLarge", GameFontDisableLarge},
	{"QuestFontNormalSmall", QuestFontNormalSmall},
	{"DialogButtonHighlightText",  DialogButtonHighlightText},
	{"ErrorFont", ErrorFont},
	{"TextStatusBarText", TextStatusBarText},
	{"CombatLogFont", CombatLogFont},
	{"GameTooltipText", GameTooltipText},
	{"GameTooltipTextSmall", GameTooltipTextSmall},
}

local FontFrame = nil
function SmartQuestLog:Fonts(msg)
	if fontFrame then return end
	
	local fontFrame = AceGUI:Create("Window")
	fontFrame:SetCallback("OnClose", function()
		FontFrame = nil	
	end)

	fontFrame:SetLayout("List")
	fontFrame:SetWidth(200)
	fontFrame:SetHeight(400)
	fontFrame:EnableResize(false)
	-- fontFrame:SetPoint("LEFT", 0, 110)
	-- fontFrame:SetPoint("CENTER", 0, -180)
	-- fontFrame.frame:SetFrameStrata("LOW")
	
	for i=9, 14, 0.5 do
		local label = AceGUI:Create("Label")    
		label:SetFullWidth(true)
		label.label:SetMaxLines(1)
		label.label:SetFont("Fonts\\FRIZQT__.TTF", i)
		-- local name = f.GetName()
		label:SetText("Grove of the ancients " .. tostring(i))
		fontFrame:AddChild(label)
	end
	
	fontFrame:Show()
end