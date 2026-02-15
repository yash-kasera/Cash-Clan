local TerrainHelper = {}

-- CONSTANTS (Must match server config or be passed in)
local SEED = 2026
local SCALE_CONTINENT = 800
local SCALE_EROSION = 400
local SCALE_TEMP = 2500
local SCALE_HUMIDITY = 2500
local SEA_LEVEL = 0

TerrainHelper.BiomeType = {
	Ocean = "Ocean",
	DeepOcean = "DeepOcean",
	Beach = "Beach",
	Plains = "Plains",
	Forest = "Forest",
	Jungle = "Jungle",
	Desert = "Desert",
	Mountain = "Mountain",
	Snow = "Snow",
	Swamp = "Swamp",
	SpruceForest = "SpruceForest",
}

-- Colors for Map
TerrainHelper.BiomeColors = {
	Ocean = Color3.fromRGB(50, 100, 200),
	DeepOcean = Color3.fromRGB(20, 40, 100),
	Beach = Color3.fromRGB(255, 220, 150),
	Plains = Color3.fromRGB(100, 200, 100),
	Forest = Color3.fromRGB(34, 139, 34),
	Jungle = Color3.fromRGB(0, 100, 0),
	Desert = Color3.fromRGB(230, 200, 100),
	Mountain = Color3.fromRGB(120, 120, 120),
	Snow = Color3.fromRGB(240, 240, 240),
	Swamp = Color3.fromRGB(60, 80, 50),
	SpruceForest = Color3.fromRGB(50, 80, 60),
}

local function smoothstep(edge0, edge1, x)
	x = math.clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return x * x * (3 - 2 * x)
end

local function getRidgeNoise(x, z, seed, scale)
	local n = math.noise(x / scale, z / scale, seed)
	return 1 - math.abs(n)
end

function TerrainHelper.GetTerrainData(worldX, worldZ)
	local continentalness = math.noise(worldX / SCALE_CONTINENT, worldZ / SCALE_CONTINENT, SEED)
	local erosion = math.noise(worldX / SCALE_EROSION, worldZ / SCALE_EROSION, SEED + 1)
	local temp = math.noise(worldX / SCALE_TEMP, worldZ / SCALE_TEMP, SEED + 2)
	local humidity = math.noise(worldX / SCALE_HUMIDITY, worldZ / SCALE_HUMIDITY, SEED + 3)

	-- SPAWN ISLAND BIAS
	-- Force land near 0,0
	local distFromOrigin = math.sqrt(worldX ^ 2 + worldZ ^ 2)
	if distFromOrigin < 1500 then
		local bias = 1 - (distFromOrigin / 1500)
		continentalness = continentalness + (bias * 0.5) -- Add up to 0.5 to noise
	end

	local height = 0
	local biome = TerrainHelper.BiomeType.Plains

	-- OCEAN / LAND SPLIT
	if continentalness < -0.3 then
		-- Deep Ocean Trench Logic
		height = -40 + (erosion * 30) -- Shelf
		-- Blend towards -5 as we approach -0.3
		if continentalness > -0.4 then
			local blend = (continentalness - -0.4) / 0.1 -- 0 to 1
			height = smoothstep(-40, -5, blend) - 20 * (1 - blend) -- Smooth blend up
		end

		biome = TerrainHelper.BiomeType.DeepOcean
		if height > -5 then
			height = -5
		end
	elseif continentalness < 0.05 then
		biome = TerrainHelper.BiomeType.Beach
		-- Smooth blend from -5 (at -0.3) to +10 (at 0.05)
		local t = (continentalness - -0.3) / (0.05 - -0.3)
		t = math.clamp(t, 0, 1)
		height = -5 + smoothstep(0, 1, t) * 15 -- Ranges -5 to 10
	else
		-- LAND
		-- Biome Selection
		if temp > 0.6 then
			biome = TerrainHelper.BiomeType.Desert
		elseif temp < -0.6 then
			biome = TerrainHelper.BiomeType.Snow
		else
			-- Swamp Logic: High humidity, moderate temperature
			if humidity > 0.4 and temp > -0.2 and temp < 0.4 then
				biome = TerrainHelper.BiomeType.Swamp
			elseif humidity > 0.4 then
				if temp > 0.3 then
					biome = TerrainHelper.BiomeType.Jungle
				elseif temp > -0.1 then
					biome = TerrainHelper.BiomeType.Forest
				else
					biome = TerrainHelper.BiomeType.SpruceForest
				end
			else
				-- Only form mountains if erosion is high
				-- Default to Plains if not mountain
				biome = TerrainHelper.BiomeType.Plains
			end
		end

		-- Target Height Calculation
		local targetHeight = 10 -- Base level (matches Beach end)

		if biome == TerrainHelper.BiomeType.Desert then
			-- Dunes
			targetHeight = 10 + math.noise(worldX / 80, worldZ / 80, SEED) * 15
		elseif biome == TerrainHelper.BiomeType.Swamp then
			-- Low, boggy terrain near sea level
			targetHeight = SEA_LEVEL + math.noise(worldX / 50, worldZ / 50, SEED) * 4
			if targetHeight < SEA_LEVEL then
				targetHeight = targetHeight - 1
			end
		elseif biome == TerrainHelper.BiomeType.Jungle or biome == TerrainHelper.BiomeType.Forest or biome == TerrainHelper.BiomeType.SpruceForest then
			-- Hilly
			targetHeight = 15 + math.noise(worldX / 120, worldZ / 120, SEED) * 20
		elseif biome == TerrainHelper.BiomeType.Plains then
			-- Flat
			targetHeight = 10 + math.noise(worldX / 200, worldZ / 200, SEED) * 8
		else
			-- Mountains / Default High Ground
			biome = TerrainHelper.BiomeType.Mountain
			local ridge = getRidgeNoise(worldX, worldZ, SEED, 250) -- Broader mountains
			targetHeight = 20 + (ridge * 40) -- Reduced extreme height, wider base
		end

		-- Soft Blend from Coast (10) to Biome Height
		local coastBlend = smoothstep(0.05, 0.2, continentalness)
		local base = 10 -- Beach height end
		
		if biome == TerrainHelper.BiomeType.Swamp then
			height = targetHeight -- Swamps can be low near coast
		else
			height = base + (targetHeight - base) * coastBlend
		end
	end

	return height, biome
end

return TerrainHelper
