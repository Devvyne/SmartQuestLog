
SQLChainData = {}

local debug = SQLUtils.debug
local ChainMap = nil

local ERRONEOUS_QUESTS = {
	3,
}

local function printError(q)
	if not ERRONEOUS_QUESTS[q] then
		debug(1, "Error: quest missing in chain map", q)
	end
end

-- Public --

function SQLChainData:Init()
	debug(3, "Loading quest chains data...")
	ChainMap = {}
	for _, q in pairs(SQLData.AllQuests) do		
		local preQuest = SQLQuestieWrapper:_GetPreQuest(q)
		local nextQuest = SQLQuestieWrapper:_GetNextQuest(q)		
		
		self.addQuestToChainMap(q, preQuest, nextQuest, 0, 1)
		if preQuest then self.addQuestToChainMap(preQuest, nil, q, 0, 0) end
		if nextQuest then self.addQuestToChainMap(nextQuest, q, nil, 1, 0) end
	end		
end

function SQLData:GetQuestChain(questId, includePreQuests)
	local chain = { questId }	
	
	if SQLData:GetQuestType(questId) ~= SQLData.QuestType.REGULAR then  -- We dont support quests other than regular at the moment
		return chain
	end
	
	if includePreQuests then
		local preQuestId = self:GetPreQuest(questId)
		while preQuestId  ~= nil do
			table.insert(chain, 1, preQuestId)			
			preQuestId = self:GetPreQuest(preQuestId)
		end
	end
	
	local nextQuestId = self:GetNextQuest(questId)
    while nextQuestId ~= nil do
        table.insert(chain, nextQuestId)		
		nextQuestId = self:GetNextQuest(nextQuestId)
    end
	
	return chain
end

function SQLData:ChainXp(questId)
	local chain = SQLData:GetQuestChain(questId, false)
    local chainXp = 0
	
	for _, q in pairs(chain) do
		chainXp = chainXp + SQLData:QuestXp(q)
	end
	
    return chainXp
end

function SQLData:GetPreQuest(questId)
	if not ChainMap[questId] then printError(questId); return nil end
	return ChainMap[questId][1]
end

function SQLData:GetNextQuest(questId)
	if not ChainMap[questId] then printError(questId); return nil end
	return ChainMap[questId][3]
end

-- Private --

function SQLChainData.addQuestToChainMap(questId, preQuestId, nextQuestId, overridePre, overrideNext)
	if not ChainMap[questId] then
		ChainMap[questId] = { preQuestId, overridePre, nextQuestId, overrideNext }
	else
		if ChainMap[questId][1] == nil then
			ChainMap[questId][1] = preQuestId
			ChainMap[questId][2] = overridePre
		else
			if preQuestId ~= nil and preQuestId ~= ChainMap[questId][1] then
				if overridePre > ChainMap[questId][2] then
					ChainMap[questId][1] = preQuestId
					ChainMap[questId][2] = overridePre
				elseif overridePre == ChainMap[questId][2] and overridePre == 1 then
					debug(4, "Detected prequest collision for quest", questId, "-", ChainMap[questId][1], preQuestId)
				end
			end
		end
		
		if ChainMap[questId][3] == nil then
			ChainMap[questId][3] = nextQuestId
			ChainMap[questId][4] = overrideNext
		else
			if nextQuestId ~= nil and nextQuestId ~= ChainMap[questId][3] then
				if overrideNext > ChainMap[questId][4] then
					ChainMap[questId][3] = nextQuestId
					ChainMap[questId][4] = overrideNext
				elseif overrideNext == ChainMap[questId][4] and overrideNext == 1 then
					debug(4, "Detected nextquest collision for quest", questId, "-", ChainMap[questId][3], nextQuestId)
				end
			end
		end
	end
end
