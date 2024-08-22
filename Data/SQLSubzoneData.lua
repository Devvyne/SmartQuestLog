SQLSubzoneData = {}

function SQLData:CoordinatesToSubzone(x, y, zoneId)
	local subzones = SQLSubzoneData.Subzones[zoneId]
	if not subzones then return nil end
	
	for subzone, coords in pairs(subzones) do
		x1, x2, y1, y2 = coords[1], coords[2], coords[3], coords[4]
		if x > x1 and x < x2 and y > y1 and y < y2 then
			return subzone
		end
	end
	
	return nil
end

function SQLData:SubzoneCenter(zoneId, subzoneName)
	local subzones = SQLSubzoneData.Subzones[zoneId]
	if not subzones or not subzones[subzoneName] then return nil, nil end
	
	local szRect = subzones[subzoneName]
	return (szRect[2] + szRect[1]) / 2, (szRect[4] + szRect[3]) / 2
end

SQLSubzoneData.Subzones = {
	
	-- EASTERN KINGDOMS

	[12] = {  -- Elwynn Forest
		["Goldshire"] = { 37, 45, 60, 70 },
		["Forest's Edge"] = { 22, 30, 68, 96 },
		["Fargodeep Mine"] = { 30, 46, 76, 90 },
		["Northshire Valley"] = { 43.5, 60, 29, 55 },
		["Crystal Lake"] = { 45.5, 60, 57, 71 },
		["Stonecairn Lake"] = { 67, 83, 38, 60 },
		["Tower of Azora"] = { 61, 74, 60, 73 },
		["Brackwell Pumpkin Patch"] = { 61, 74, 74, 85 },
		["Ridgepoint Tower"] = { 79, 91.5, 75.5, 85.5 },
		["Eastvale Logging Camp"] = { 77.5, 90, 60, 72.5 },
	},
	[10] = {  -- Duskwood
		["The Hushed Bank"] = { 6, 14, 30, 60 },
		["Raven Hill Cemetery"] = { 14.5, 26.5, 31.5, 51 },
		["Raven Hill"] = { 15.5, 26, 51, 61 },
		["Addle's Stead"] = { 16, 28, 62, 76.5 },
		["Vul'Gor Ogre Mound"] = { 28.5, 44, 65, 82 },
		["Yorgen Farmstead"] = { 44, 54, 65, 81 },
		["The Rotting Orchard"] = { 58, 70, 64, 82 },
		["Brightwood Grove"] = { 57, 68.5, 24.7, 57 },
		["Darkshire"] = { 70.8, 83.5, 37, 52.5 },
		["Tranquil Gardens Cemetery"] = { 71, 85, 55, 80 },
		["The Darkened Bank"] = { 21, 90, 11, 24.7 },
		["Manor Mistmantle"] = { 69, 80, 29, 37 },
	},
	[40] = { -- Westfall
		["Sentinel Hill"] = { 51, 60, 42, 58 },
		["The Dead Acre"] = { 57, 68, 55, 67 },
		["The Dust Plains"] = { 56, 71, 67, 78 },
		["Dagger Hills"] = { 37, 56, 75.5, 84.5 },
		["Westfall Lighthouse"] = { 26, 37, 79, 93 },
		["Demont's Place"] = { 26, 37, 63, 78 },
		["Moonbrook"] = { 39, 50, 55.5, 75.5 },
		["Alexston Farmstead"] = { 35, 44, 45, 60 },
		["Gold Coast Quarry"] = { 25, 35, 34, 50 },
		["Jangolode Mine"] = { 40, 47, 15, 30 },
		["Furlbrow's Pumpkin Farm"] = { 47, 52, 15, 27.5 },
		["The Jansen Stead"] = { 52, 61, 10, 24 },
		["The Molsen Farm"] = { 39, 50.5, 30, 43 },
		["Saldean's Farm"] = { 50.5, 60, 27.5, 40 },
	},
	
	
	[11] = { -- Wetlands
		["Menethil Harbor"] = { 5, 13.5, 50, 64 },
		["Bluegill Marsh"] = { 10, 26, 23, 42 },
		["Sundown Marsh"] = { 26, 32, 22, 39 },
		["Black Channel Marsh"] = { 13.5, 30.5, 41, 61 },
		["Whelgar's Excavation Site"] = { 30.5, 41, 39, 53 },
		["Saltspray Glen"] = { 32, 41, 14, 35 },
		["Ironbeard's Tomb"] = { 41, 50, 22, 39 },
		["Dun Modr"] = { 44, 55, 10, 25 },
		["Direforge Hill"] = { 60, 64, 23, 40 },
		["The Green Belt"] = { 50, 59, 25, 47.75 },
		["Dragonmaw Gates"] = { 68, 94, 40, 86 },
		["Mosshide Fen"] = { 56, 68, 47.75, 59 },
		["Thelgen Rock"] = { 42, 66, 59, 78 },
		["Angerfang Encampment"] = { 41, 55, 40, 56 },
	},
	
	-- KALIMDOR
	
	[141] = { -- Teldrassil
		["Shadowglen"] = { 53, 67, 27, 50 },
		["Starbreeze Village"] = { 61, 71, 51, 63 },
		["Dolanaar"] = { 51, 61, 50, 63 },
		["Lake Al'Ameth"] = { 50, 65, 50, 79 },
		["Ban'ethil Hollow"] = { 42.42, 51, 45.5, 69 },
		["Pools of Arlithrien"] = { 36, 42.42, 55, 69 },
		["Gnarlpine Hold"] = { 36, 50, 69, 82 },
		["The Oracle Glade"] = { 30, 39, 22, 48 },
		["Wellspring Lake"] = { 39, 53, 22, 45.5},
		["Rut'theran Village"] = { 52, 61, 85, 100 },
	},
	[148] = { -- Darkshore
		["Auberdine"] = { 35, 43, 40.1, 51 },
		["Bashal'Aran"] = { 41, 48, 31, 40.1 },
		["Cliffspring River"] = { 48, 59, 30.5, 39 },
		["Tower of Althalaxx"] = { 52, 61, 24, 30.5 },
		["Ruins of Mathystra"] = { 55.5, 63, 9, 24 },
		["Ameth'Aran"] = { 38, 47, 51, 63 },
		["Grove of the Ancients"] = { 38, 47, 71, 83 },
		["The Master's Glaive"] = { 38, 47, 83, 95 },
		["Remtravel's Excavation"] = { 32, 38, 83, 90 },
	},
	[331] = { -- Ashenvale
		["Maestra's Post"] = { 24, 31, 27, 42 },
		["Bathran's Haunt"] = { 28, 36, 16, 27 },
		["Thristlefur Village"] = { 31, 43, 37, 45 },
		["Shrine of Aessina"] = { 16, 28, 46, 60 },
		["Astranaar"] = { 31, 43, 45, 59 },
		["Fire Scar Shrine"] = { 23.5, 30, 60, 69 },
		["Ruins of Stardust"] = { 30, 38, 60, 73 },
		["Iris Lake"] = { 43, 50, 40, 56 },
		["Greenpaw Village"] = { 48, 60, 58, 65 },
		["Mystral Lake"] = { 42, 57, 65, 82 },
		["Raynewood Retreat"] = { 56, 66, 45, 58 },
		["The Howling Vale"] = { 48, 63, 31, 44 },
		["Night Run"] = { 66, 76, 51, 57 },
		["Splintertree Post"] = { 70, 78, 57, 67 },
		["Satyrnaar"] = { 76, 89, 41, 53 },
		["Bough Shadow"] = { 89, 98, 29, 43 },
		["Warsong Lumber Camp"] = { 85, 95, 53, 65 },
		["Fallen Sky Lake"] = { 61, 74, 72, 88 },
		["Felfire Hill"] = { 74, 93, 70, 85 },
		["The Zoram Strand"] = { 4, 22, 10, 36 },
		["Lake Falathim"] = { 17, 24, 36, 46 },
	},
	[406] = { -- Stonetalon Mountains
		["Stonetalon Peak"] = { 26, 47, 2, 22 },
		["Mirkfallon Lake"] = { 42, 56, 32, 49 },
		["Sun Rock Retreat"] = { 40, 52, 49, 66 },
		["The Charred Vale"] = { 24, 40, 40, 83 },
		["Windshear Crag"] = { 56, 86, 31, 65 },
		["Malaka'jin"] = { 69, 76.2, 90.7, 100 },
		["Camp Aparaje"] = { 76.2, 81, 89.5, 95 },
	},
	[15] = { -- Dustwallow Marsh (TODO Complete)
		["Theramore"] = { 62, 75, 42, 61 },
		["Sentry Point"] = { 57, 62, 36.5, 45.5 },
		["North Point Tower"] = { 44.5, 50, 21, 30 },
		["Witch Hill"] = { 50, 63.5, 18, 36.5 },
		["Bluefen"] = { 38, 44.5, 15, 36.5 },
		["Darkmist Cavern"] = { 28, 38, 15, 25 },
		["Brackenwall Village"] = { 28, 38, 25, 39 },
	},
	[405] = { -- Desolace (TODO Complete)
		["Nijel's Point"] = { 60, 70, 5, 14 },
		["Sargeron"] = { 69.5, 83, 14, 31 },
		["Thunder Axe Fortress"] = { 49, 60, 22.5, 34 },
		["Kolkar Village"] = { 67, 76, 36, 57 },
		["Kodo Graveyard"] = { 44, 58, 48, 67.5 },
		["Ethel Rethor"] = { 34, 48, 20, 41 },
		["Kormek's Hut"] = { 59, 66, 34, 47 },
		["Ranazjar Isle"] = { 25, 35, 4, 17.5 },
		["Mannoroc Coven"] = { 45, 58.2, 67.5, 88.5 },
		["Magram Village"] = { 65, 77, 63, 83.5 },
		["Gelkis Village"] = { 32, 45, 77, 97 },
		["Valley of Spears"] = { 25, 41.5, 39, 66 },
	},
}