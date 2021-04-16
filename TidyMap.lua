
TIDY_MAP 					= {}
TIDY_MAP.name 				= "TidyMap"
TIDY_MAP.version 			= "1.0"

local defaults = {
	hideTamrielWayhsrines = 0,
	hideTamrielDungeons = false,
	hideTamrielTrials = false,
	unownedHouses = 0,
	ownedHouses = 0,
	hideTamriel = false,
	NodeOverwrite = {}
}

local arena = {
	[250] = true, -- Maelstrom Arena
	[270] = true, -- Dragonstar Arena
	[378] = true, -- Blackrose Prison
	[457] = true, -- Vateshran Hollows
}

--[[
for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end
]]

local function UpdateMapPins()

	local isCapitalWayshrine = {
		[28]  = true, -- Deshaan: Mournhold
		[33]  = true, -- Bangkorai: Evermore
		[43]  = true, -- Alik'r Desert: Sentinel
		[44]  = true, -- Alik'r Desert: Bergama
		[48]  = true, -- Shadowfen: Stormhold
		[55]  = true, -- Rivenspire: Stornhelm
		[56]  = true, -- Stormhaven: Wayrest
		[62]  = true, -- Glenumbra: Daggerfall
		[65]  = true, -- Stonefalls: Davon's Watch
		[67]  = true, -- Stonefalls: Ebonheart
		[87]  = true, -- Eastmarch: Windhelm
		[102] = true, -- Malabal Tor: Velyn Harbor
		[106] = true, -- Malabal Tor: Baandari TradingPost
		[109] = true, -- The Rift: Riften
		[121] = true, -- Auridon: Skywatch
		[138] = true, -- Stros M'Kai: Port Hunding
		[142] = true, -- Khenarthi's Roost: Mistral
		[143] = true, -- Greenshade: Marbruk
		[162] = true, -- Reaper's March: Rawl'kha
		[172] = true, -- Bleakrock Isle: Bleakrock
		[173] = true, -- Bal Foyen: Dhalmora
		[177] = true, -- Auridon: Vulkheel Guard
		[181] = true, -- Betnikh: Stonetooth
		[214] = true, -- Grahtwood: Elden Root
		[215] = true, -- Eyevea: Eyevea
		[220] = true, -- Craglorn: Belkarth
		[244] = true, -- Wrothgar: Orsinium
		[251] = true, -- Gold Coast: Anvil
		[252] = true, -- Gold Coast: Kvatch
		[255] = true, -- Hew's Bane: Abah's Landing
		[284] = true, -- Vvardenfell: Vivec City
		[350] = true, -- Summerset: Shimmerine
		[355] = true, -- Summerset: Alinor
		[374] = true, -- Murkmire: Lilmoth
		[382] = true, -- Northern Elsweyr: Rimmen
		[402] = true, -- Southern Elsweyr: Senchal
		[421] = true, -- Western Skyrim: Solitude
		[449] = true, -- The Reach: Markarth
	}

	local hideAll 						= false
	local hideAllWayshrines 			= false
	local hideAllWayshrinesNonCapital 	= true
	local hideAllDungeons 				= true
	local hideAllTrials 				= true
	local hideAllHousesOwned 			= true
	local hideAllHousesUnowned 			= true
	local showUnknownWayshrines 		= true


	local unownedHouse 		= "/esoui/art/icons/poi/poi_group_house_unowned.dds"
    local   ownedHouse 		= "/esoui/art/icons/poi/poi_group_house_owned.dds"
    local    glowHouse 		= "/esoui/art/icons/poi/poi_group_house_glow.dds"
    local unknownWayshrine 	= "/esoui/art/icons/poi/poi_wayshrine_incomplete.dds"
    local pickleIcon 		= "TidyMap/textures/happy_pickle.dds"

	local originalTravelNodeFun = GetFastTravelNodeInfo
	local originalPOIFun = GetPOIMapInfo

	GetFastTravelNodeInfo = function(nodeIndex, ...)
	
		local known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isShownInCurrentMap, linkedCollectibleIsLocked = originalTravelNodeFun(nodeIndex, ...)

		--if nodeIndex < 100 then	df("%s => %s", name, tostring(nodeIndex)) end

		-- pre-reset all pins to default (fixes bug if known = false then it stays flase until re-log)
		if poiType ~= POI_TYPE_HOUSE and (arena[nodeIndex] ~= nil and not arena[nodeIndex]) then known = true end

		if GetMapType() == MAPTYPE_WORLD then
			-- check if node is known and in overwrite
			--if(SV.NodeOverwrite ~= nil and SV.NodeOverwrite[nodeIndex] ~= nil) then
			--	known = known and SV.NodeOverwrite[nodeIndex]
			--else
				if hideAll then -- Hide Everything
					known = false
				else
					if poiType == POI_TYPE_WAYSHRINE then -- Wayshrines
						
						if showUnknownWayshrines and isCapitalWayshrine[nodeIndex] and known ~= true then
							known = true
							glowIcon = false
							icon = unknownWayshrine
						else
							if (hideAllWayshrinesNonCapital and not isCapitalWayshrine[nodeIndex]) -- hide execpt capitals
								or hideAllWayshrines then -- hide all 
									known = false
							end							
						end				
					elseif poiType == POI_TYPE_GROUP_DUNGEON or (arena[nodeIndex] ~= nil and arena[nodeIndex]) then -- Dungeons & Arenas
						if hideAllDungeons then known = false end
					elseif poiType == POI_TYPE_ACHIEVEMENT then -- Trials
						if hideAllTrials then known = false	end
					elseif poiType == POI_TYPE_HOUSE then -- Houses
						if hideAllHousesOwned and icon == ownedHouse then known = false	end -- Unowned Houses
						if hideAllHousesUnowned and icon == unownedHouse then known = false end -- Owned Houses
					end
				end
			--end
		else -- zone, etc

			-- pre-reset all pins to default (fixes bug if known = false then it stays flase until re-log)
			if icon == ownedHouse and icon == unownedHouse and arena[nodeIndex] ~= nil and not arena[nodeIndex] then known = true end
			
			-- show all unknown Wayshrines
			if showUnknownWayshrines and poiType == POI_TYPE_WAYSHRINE then
				if known ~= true then
					known = true
					glowIcon = false
					icon = unknownWayshrine
				end
			end

			--	Hide houses even on zone map
			--[[
			if poiType == POI_TYPE_HOUSE then
				-- Unowned Houses
				if hideAllHousesOwned and icon == ownedHouse then known = false	end
				-- Owned Houses
				if hideAllHousesUnowned and icon == unownedHouse then known = false end
			end
			]]


		end
		
		return known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isShownInCurrentMap, linkedCollectibleIsLocked
	end
	
	GetPOIMapInfo = function(zoneIndex, poiIndex, ...)
	
		local normalizedX, normalizedZ, poiType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = originalPOIFun(zoneIndex, poiIndex, ...)
		
		--Unowned Houses
			--Hide Everything
		if hideAllHousesUnowned and icon == unownedHouse then
			isDiscovered = false
			isNearby = false
		end

		return normalizedX, normalizedZ, poiType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby
	end
end

EVENT_MANAGER:RegisterForEvent(
	TIDY_MAP.name.."_OnPlayerActivated", EVENT_PLAYER_ACTIVATED,
	function(_, addOnName)
		--if(addOnName ~= TIDY_MAP.name) then return end
		UpdateMapPins()
		EVENT_MANAGER:UnregisterForEvent(TIDY_MAP.name.."_OnPlayerActivated", EVENT_PLAYER_ACTIVATED)
	end
)