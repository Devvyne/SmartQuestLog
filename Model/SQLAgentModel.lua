SQLAgentModel = {}


local debug = SQLUtils.debug
local AgentType = SQLData.AgentType


function SQLAgentModel.Agent(agentId, agentType)
	local name = SQLData:GetAgentName(agentId, agentType)
	if not name then return nil end
	
	local spawns = SQLData:GetAgentSpawns(agentId, agentType)
	local minLevel = 0
	local maxLevel = 0
	local droppers = {}
	
	if agentType == AgentType.NPC then
		minLevel, maxLevel = SQLData:GetNPCLevels(agentId)
	end
	
	if agentType == AgentType.ITEM then
		for _, p in pairs(SQLData:GetItemDroppers(agentId)) do
			table.insert(droppers, SQLAgentModel.Agent(p[1], p[2])) 
		end
	end
	
	return {
		id = agentId,
		type = agentType,
		name = name,
		minLevel = minLevel,
		maxLevel = maxLevel,
		spawns = spawns,
		droppers = droppers,
		zones = SQLAgentModel._Agent_Zones,
		subzones = SQLAgentModel._Agent_Subzones,
	}
end

function SQLAgentModel._Agent_Zones(agent)
	if agent._cachedZones then return agent._cachedZones end

	local zones = {}
	
	if agent.type == AgentType.ITEM then
		for _, dropper in pairs(agent.droppers) do
			for z, _ in pairs(dropper:zones()) do
				zones[z] = true
			end
		end
	else
		for z, _ in pairs(agent.spawns) do
			zones[z] = true
		end
	end
	
	agent._cachedZones = zones
	return zones
end

function SQLAgentModel._Agent_Subzones(agent, parentZoneId)
	if not parentZoneId then debug(1, "Error in Agent:subzones() - parent zone id is nil"); return {} end
	if agent._cachedSubzones then return agent._cachedSubzones end

	local subzones = {}
	local defaultSubzone = SQLData:GetZoneName(parentZoneId)
	
	if agent.type == AgentType.ITEM then
		for _, dropper in pairs(agent.droppers) do
			for subzone, subzoneCount in pairs(dropper:subzones(parentZoneId)) do
				SQLUtils.addSumEntry(subzones, subzone, subzoneCount)				
			end
		end
	else
		local spawns = agent.spawns[parentZoneId]
		if not spawns then return {} end		
		
		for _, spawn in pairs(spawns) do
			x, y = spawn[1], spawn[2]
			local subzone = SQLData:CoordinatesToSubzone(x, y, parentZoneId)
			if not subzone then subzone = defaultSubzone end			
			SQLUtils.addSumEntry(subzones, subzone, 1)			
		end
	end
	
	agent._cachedSubzones = subzones
	return subzones
end