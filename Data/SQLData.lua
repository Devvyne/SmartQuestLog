SQLData = {}

local debug = SQLUtils.debug



SQLData.QuestType = {
	REGULAR = 1,
	REPEATABLE = 2,
	EVENT = 3,
	NA = 4,
}

SQLData.AgentType = {
	NPC = "NPC",
	GAME_OBJECT = "Game object",
	ITEM = "Item",
	EVENT = "Event",
	REPUTATION = "Reputation",
	VENDOR = "Vendor",
	RUNE = "Rune",
}


SQLData.AllQuests = nil

function SQLData:Init()
	debug(1, "Initializing data model...")
	self.AllQuests = SQLQuestieWrapper:AllQuests()
	SQLChainData:Init()
end

