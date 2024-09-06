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
		["Northshire Valley"] = { 43.5, 58.5, 25, 55 },
		["Jasperlode Mine"] = { 58.5, 67, 46, 57 },
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
		["Dagger Hills"] = { 37, 56, 75.5, 91 },
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
	[44] = { -- Redridge Mountains (TODO Complete)
		["Lakeshire"] = { 16.5, 34, 38, 60.5 },
		["Three Corners"] = { 9, 27, 60.5, 88},
		["Lakeridge Highway"] = { 27, 54, 66, 85},
		["Lake Everstill"] = { 34, 59.5, 48.5, 66},
		
	},
	[33] = { -- Stranglethorn Vale (TODO missing 2-3 small areas)
		["Zul'Gurub"] = { 53.3, 78, 0, 40 },
		["Rebel Camp"] = { 33, 41.5, 0, 9 },
		["Kurzen's Compound"] = { 41.5, 50, 0, 15 },
		["Nesingwary's Expedition"] = { 30.5, 37.5, 9, 17 },
		["Grom'Gol Basecamp"] = { 29, 35, 24, 31 },
		["The Vile Reef"] = { 18, 29, 21, 35 },
		
		["Ruins of Zul'Kunda"] = { 22.5, 30, 7, 17 },
		["Zuuldaia Ruins"] = { 19, 22.5, 12, 21 },
		["Mizjah Ruins"] = { 35, 39, 27, 32 },
		["Bal'lal Ruins"] = { 27, 32, 17, 21 },
		["Kal'ai Ruins"] = { 32, 37, 18, 24 },
		["Balia'mah Ruins"] = { 39, 45, 27, 35 },
		["Mosh'Ogg Ogre Mound"] = { 45, 53.3, 24, 36 },
		["Lake Nazferiti"] = { 37.5, 46.5, 15, 24 },
		
		["Ziata'jai Ruins"] = { 38, 43, 35, 47 },
		["Ruins of Zul'Mamwe"] = { 43, 50, 37.5, 47 },
		["Gurubashi Arena"] = { 25, 33.5, 38, 50 },
		["Bloodsail Compound"] = { 21.5, 32, 50, 57.5 },
		["Ruins of Jubuwal"] = { 33.5, 38, 48.5, 55 },
		["Mistvale Valley"] = { 32, 37, 56, 69 },
		["Ruins of Aboraz"] = { 37, 42, 55, 63 },
		["Nek'mani Wellspring"] = { 23, 29, 57.5, 67.5 },
		["Booty Bay"] = { 22, 30.5, 69, 79 },
		["Wild Shore"] = { 26, 34, 79, 92 },
	},	
	[4] = { -- Blasted Lands
		["Dreadmaul Hold"] = { 37, 48, 8, 18 },
		["Garrison Armory"] = { 52, 60, 8, 18 },
		["Nethergarde Keep"] = { 60, 70, 8, 27 },
		["Rise of the Defiler"] = { 43, 53, 22, 37 },
		["Altar of Storms"] = { 34, 43, 27, 38 },
		["Serpent's Coil"] = { 57, 70, 27, 38 },
		["Dreadmaul Post"] = { 46, 56, 38, 48.5 },
		["The Dark Portal"] = { 51, 65, 48.5, 65 },
		["The Tainted Scar"] = { 26, 46, 44, 81 },
	},	
	
	[1] = { -- Dun Morough
		["Coldridge Valley"] = { 18, 32, 64, 85 },
		["Coldridge Pass"] = { 18, 38, 63, 74 },
		["The Grizzled Den"] = { 39, 44.2, 53, 66 },
		["Chillbreeze Valley"] = { 32, 39, 48, 56 },
		["Shimmer Ridge"] = { 38, 44.2, 33, 48 },
		["Iceflow Lake"] = { 31, 38, 29, 48 },
		["Brewnall Village"] = { 28, 31, 41, 50 },
		["Gnomeregan"] = { 20, 28, 32, 45 },
		["Frostmane Hold"] = { 20, 30.5, 48, 56 },
		
		
		["Kharanos"] = { 44.2, 54, 43, 54 },
		["Gates of Ironforge"] = { 44.2, 54, 30.5, 43 },
		["Misty Pine Refuge"] = { 54, 60.5, 36.5, 50 },
		["Amberstill Ranch"] = { 60.5, 65, 47, 54 },
		["Gol'Bolar Quarry"] = { 65, 73.5, 51, 65 },
		
		["North Gate Outpost"] = { 78, 88, 26, 45.7 },
		["South Gate Outpost"] = { 82.3, 91, 45.7, 56.2 },
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
	
	[45] = { -- Arathi Highlands
		["Circle of West Binding"] = { 20, 28, 24, 36 },
		["Northfold Manor"] = { 28, 36, 22, 34 },
		["Boulder'gor"] = { 31, 40.5, 34, 51 },
		["Stromgarde Keep"] = { 14, 31, 49, 73 },
		["Circle of Inner Binding"] = { 31, 43, 53, 69 },
		["Faldir's Cove"] = { 21, 40.5, 71, 93 },
		["Thandol Span"] = { 40.5, 51.5, 69, 96 },
		["Boulderfist Hall"] = { 51.5, 60, 64, 85 },
		["Witherbark Village"] = { 60, 74, 51, 74 },
		["Hammerfall"] = { 69, 88, 26, 46 },
		["Circle of East Binding"] = { 59.5, 69, 23, 34 },
		["Dabyrie's Farmstead"] = { 50, 60, 34, 44 },
		["Circle of Outer Binding"] = { 50, 57, 44, 57 },
		["Refuge Point"] = { 40.5, 50, 39, 55 },
		
	},
	[267] = { -- Hillsbrad Foothills
		["Southshore"] = { 46, 55, 45, 65 },
		["Western Strand"] = { 24, 46, 63, 74 },
		["Purgation Isle"] = { 10, 24, 70, 88 },
		["Azurelode Mine"] = { 21, 32, 53, 63 },
		["Southpoint Tower"] = { 17, 25, 44, 53 },
		["Hillsbrad Fields"] = { 25, 43.5, 31, 53 },
		["Darrow Hill"] = { 43.5, 58, 29, 40 },
		["Tarren Mill"] = { 58, 67.5, 12, 36.5 },
		["Durnholde Keep"] = { 67.5, 85, 19, 53 },
		["Nethander Stead"] = { 55, 67.5, 45, 67 },
		["Eastern Strand"] = { 55, 67.5, 67, 88 },
		["Dun Garok"] = { 67.5, 81, 60, 94 },
		
	},
	[36] = { -- Alterac Mountains
		["Dalaran"] = { 6, 25, 52, 78 },
		["Lordamere Camp"] = { 15, 25, 79, 92 },
		["Gavin's Naze"] = { 26, 34.5, 75.5, 93 },
		["The Headland"] = { 34.5, 43.5, 75.5, 98 },
		["Corrahn's Dagger"] = { 43.5, 53, 74.5, 95 },
		["Sofera's Naze"] = { 54, 70, 52, 76 },
		["Chillwind Point"] = { 70, 96, 50, 84 },
		
		["Growless Cave"] = { 32, 45, 63, 74.5 },
		["Ruins of Alterac"] = { 33.5, 43, 37, 63 },
		["Crushridge Hold"] = { 43, 53, 32, 52 },
		["Gallow's Corner"] = { 43, 54, 52, 64 },
		
		["Strahnbrad"] = { 55, 70, 37, 52 },
		["The Uplands"] = { 53, 69, 15, 37 },
		["Dandred's Fold"] = { 36, 50, 10, 24 },
		["Misty Shore"] = { 26, 33.5, 28.5, 47 },
		
		
	},
	
	
	
	-- KALIMDOR
	
	[141] = { -- Teldrassil
		["Shadowglen"] = { 53, 67, 24, 50 },
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
	[15] = { -- Dustwallow Marsh
		["Theramore"] = { 62, 75, 42, 61 },
		["Sentry Point"] = { 57, 62, 36.5, 45.5 },
		["North Point Tower"] = { 44.5, 50, 21, 30 },
		["Witch Hill"] = { 50, 63.5, 18, 36.5 },
		["Bluefen"] = { 38, 44.5, 15, 36.5 },
		["Darkmist Cavern"] = { 28, 38, 15, 25 },
		["Brackenwall Village"] = { 28, 38, 25, 37 },
		["The Quagmire"] = { 32, 57, 37, 61 },
		["Den of Flame"] = { 27, 40, 60, 77 },
		["Stonemaul Ruins"] = { 40, 48, 62, 71 },
		["Wyrmbog"] = { 48, 62, 65, 89 },
		["Alcaz Island"] = { 68, 84, 5, 28 },
	},
	[405] = { -- Desolace
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
		["Valley of Spears"] = { 25, 41.5, 39, 65 },
		["Shadowprey Village"] = { 19, 30, 65, 78 },
	},
	[357] = { -- Feralas
		["The Lower Wilds"] = { 79.5, 92, 36, 51 },
		["Camp Mojache"] = { 71, 79.5, 36, 47 },
		["Gordunni Outpost"] = { 72, 82.5, 23, 36 },
		["Grimtotem Compound"] = { 64, 71, 32, 48 },
		["The Writhing Deep"] = { 66, 81.5, 51, 71 },
		["Dire Maul"] = { 52, 64, 35, 52 },
		["Ruins of Isildien"] = { 57.5, 66, 52, 78 },
		["Frayfeather Highlands"] = { 50, 57.5, 61.5, 80 },
		["Feral Scar Vale"] = { 50, 57.5, 52, 61.5 },
		["Forgotten Coast"] = { 34, 50, 33, 83 },
		["The Twin Colossals"] = { 36, 56, 15, 33 },
		["Ruins of Ravenwind"] = { 36, 45, 6, 15 },
		["Jademir Lake"] = { 45, 57, 2, 15 },
		["Sardor Isle"] = { 24, 34, 38, 58 },
		["Isle of Dread"] = { 22, 37, 60, 97 },
		
	},
}