local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

if Workspace:FindFirstChild("Baseplate") then
	Workspace.Baseplate:Destroy()
end

local StructureManager = require(script.Parent.StructureManager)
local TownManager = require(script.Parent.TownManager)
local BuildingGenerator = require(script.Parent.BuildingGenerator)

local TerrainHelper = require(game.ReplicatedStorage.Shared.TerrainHelper)
local BiomeType = TerrainHelper.BiomeType

-- Configuration
local SEED = 2026 -- Keep for TownManager if needed, but Helper has its own
local CHUNK_SIZE = 16
local RENDER_DISTANCE = 8 -- Far view
local VOXEL_SIZE = 4
local SEA_LEVEL = 0
local BEDROCK_LEVEL = -150

local generatedChunks = {}
local terrain = Workspace.Terrain
local StructuresFolder = workspace:FindFirstChild("Structures") or Instance.new("Folder")
StructuresFolder.Name = "Structures"
StructuresFolder.Parent = workspace
StructuresFolder:ClearAllChildren() -- Clear old structures on reload

-- Math Helpers
local function getRidgeNoise(x, z, seed, scale)
	local n = math.noise(x / scale, z / scale, seed)
	return 1 - math.abs(n)
end

-- --- TERRAIN LOGIC ---
-- Proxy to Shared Helper
local function getTerrainData(worldX, worldZ)
	return TerrainHelper.GetTerrainData(worldX, worldZ)
end

local function getMaterial(biome, height, slope)
	if biome == BiomeType.DeepOcean then
		return Enum.Material.Slate
	end -- Dark
	if biome == BiomeType.Ocean then
		return Enum.Material.Sand
	end
	if biome == BiomeType.Beach or biome == BiomeType.Desert then
		return Enum.Material.Sand
	end
	if biome == BiomeType.Swamp then
		-- Mud if strictly land, or Ground/Grass
		if height <= SEA_LEVEL then
			return Enum.Material.Mud -- Underwater swamp floor
		end
		return Enum.Material.Grass -- Gloomy grass handled by color correction ideally, but material wise Grass is fine
	end
	if biome == BiomeType.SpruceForest then
		return Enum.Material.Ground
	end
	if biome == BiomeType.Mountain then
		if height > 110 then
			return Enum.Material.Snow
		end
		if slope > 0.6 then
			return Enum.Material.Rock
		end
		return Enum.Material.Slate
	end
	if biome == BiomeType.Jungle then
		return Enum.Material.Ground
	end
	return Enum.Material.Grass -- Default
end

local function generateChunk(cx, cz)
	local key = cx .. ":" .. cz
	if generatedChunks[key] then
		return
	end
	generatedChunks[key] = true

	local xStart = cx * CHUNK_SIZE
	local zStart = cz * CHUNK_SIZE

	-- local structuresToPlace = {}

	-- Check City Status
	local townData = TownManager.GetTownAt(cx, cz)

	-- GENERATE VOXELS
	local heights = {} -- Cache for structures

	for x = 0, CHUNK_SIZE - 1 do
		heights[x] = {}
		for z = 0, CHUNK_SIZE - 1 do
			local worldX = (xStart + x) * VOXEL_SIZE
			local worldZ = (zStart + z) * VOXEL_SIZE

			local h, biome = getTerrainData(worldX, worldZ)
			
			-- Biome Blending (Dithering)
			-- Sample biome at a noisy offset to create irregular edges
			local jitter = 12 -- Blend range in studs
			local jx = worldX + (math.random() * jitter * 2 - jitter)
			local jz = worldZ + (math.random() * jitter * 2 - jitter)
			local _, visualBiome = getTerrainData(jx, jz)
			
			-- Use visualBiome for material, but keep original height and physical biome logic
			-- actually, we might want to keep 'biome' as visualBiome for the rest of this loop (structure spawning etc)
			-- But structures should spawn based on the logical biome (center of voxel).
			-- Materials should use the Blended biome.
			
			local renderBiome = visualBiome

			-- Flatten terrain for Cities
			if townData and h > SEA_LEVEL then
				local targetH = 15 -- standard city level

				-- Calculate distance from town center to current voxel (in chunks approximation)
				-- We need stud-level distance for smooth blending
				-- townData has CenterChunkX/Z.
				-- Voxel world pos: worldX, worldZ

				local centerStudX = townData.CenterChunkX * CHUNK_SIZE * VOXEL_SIZE
				local centerStudZ = townData.CenterChunkZ * CHUNK_SIZE * VOXEL_SIZE
				local distStuds = math.sqrt((worldX - centerStudX) ^ 2 + (worldZ - centerStudZ) ^ 2)
				local radiusStuds = townData.RadiusChunks * CHUNK_SIZE * VOXEL_SIZE

				-- Blur edge: last 100 studs?
				local edgeBlur = 100
				local blend = 1.0

				if distStuds > (radiusStuds - edgeBlur) then
					local t = (distStuds - (radiusStuds - edgeBlur)) / edgeBlur
					blend = 1.0 - math.clamp(t, 0, 1) -- 1 near center, 0 at border
				end

				if blend > 0 then
					-- Lerp height
					h = h * (1 - blend) + targetH * blend

					if blend > 0.5 then
						biome = BiomeType.Plains
					end
				end
			end

			heights[x][z] = { H = h, B = biome }

			-- Fill
			local bottom = BEDROCK_LEVEL
			local diff = h - bottom
			if diff > 0 then
				local mat = getMaterial(renderBiome, h, 0)
				local cf = CFrame.new(worldX, bottom + diff / 2, worldZ)
				terrain:FillBlock(cf, Vector3.new(VOXEL_SIZE, diff, VOXEL_SIZE), mat)
			end

			-- Water
			if h < SEA_LEVEL then
				terrain:FillBlock(
					CFrame.new(worldX, h + (SEA_LEVEL - h) / 2, worldZ),
					Vector3.new(VOXEL_SIZE, SEA_LEVEL - h, VOXEL_SIZE),
					Enum.Material.Water
				)
			end
		end
		if x % 8 == 0 then
			RunService.Heartbeat:Wait()
		end
	end

	-- PLACE STRUCTURES / DETAILS
	-- Helper to pick building based on town seed & pos
	local function pickBuilding(bx, bz)
		local buildingList = {
			"CarShowroom",
			"BikeShowroom",
			"TruckShowroom",
			"Nursery",
			"ToolsShop",
			"Restaurant",
			"Cafe",
			"Hotel",
			"Apartment",
			"Factory",
			"BuilderCompany",
			"Bank",
			"Hospital",
			"School",
			"Mall",
			"PoliceStation",
		}

		-- Use a hash of coords + town seed
		local val = math.noise(bx / 10, bz / 10, townData.Seed)
		local idx = math.abs(math.floor(val * 100)) % #buildingList + 1
		return buildingList[idx]
	end

	for x = 0, CHUNK_SIZE - 1, 1 do -- Check every voxel? No, skip for performance
		for z = 0, CHUNK_SIZE - 1, 1 do
			if (x + z) % 3 ~= 0 then
				continue
			end -- Optimization skip (Nature only)

			local data = heights[x][z]
			local h = data.H
			local b = data.B
			local worldX = (xStart + x) * VOXEL_SIZE
			local worldZ = (zStart + z) * VOXEL_SIZE
			local cf = CFrame.new(worldX, h, worldZ)

			if h <= SEA_LEVEL then
				-- Water Surface Decoration
				if h > (SEA_LEVEL - 1) then -- Top surface
					-- Swamp Logic for Lilypads
					if b == BiomeType.Swamp then
						-- High chance for Lilypads in Swamp
						if math.random() < 0.2 then
							StructureManager.PlaceLilypad(CFrame.new(worldX, SEA_LEVEL, worldZ), StructuresFolder)
						end
					end
				end
				continue
			end

			if not townData then
				-- NATURE LOGIC
				local function tryPlaceRock(chance)
					if math.random() < chance then
						StructureManager.PlaceRock(cf, StructuresFolder)
					end
				end

				if b == BiomeType.Forest then
					if math.random() < 0.05 then
						StructureManager.PlaceOakTree(cf, StructuresFolder) -- Used to be Pine, user requested change
					elseif math.random() < 0.08 then
						StructureManager.PlaceBush(cf, StructuresFolder)
					elseif math.random() < 0.02 then
						StructureManager.PlaceLog(cf, StructuresFolder)
					elseif math.random() < 0.02 then -- Reduced from 0.1
						StructureManager.PlaceClover(cf, StructuresFolder)
					elseif math.random() < 0.04 then
						StructureManager.PlaceMushroom(cf, StructuresFolder)
					end
					tryPlaceRock(0.002)

				elseif b == BiomeType.SpruceForest then
					if math.random() < 0.02 then -- Reduced from 0.08
						StructureManager.PlacePineTree(cf, StructuresFolder)
					elseif math.random() < 0.05 then
						StructureManager.PlaceBush(cf, StructuresFolder)
					elseif math.random() < 0.02 then
						StructureManager.PlaceLog(cf, StructuresFolder)
					end
					tryPlaceRock(0.005)

				elseif b == BiomeType.Swamp then
					-- Swamp Trees and vegetation
					if math.random() < 0.05 then
						StructureManager.PlaceOakTree(cf, StructuresFolder) -- Use Oak as "Swamp Tree" for now
					elseif math.random() < 0.05 then
						StructureManager.PlaceMushroom(cf, StructuresFolder)
					elseif math.random() < 0.05 then
						StructureManager.PlaceLog(cf, StructuresFolder)
					end
					
				elseif b == BiomeType.Jungle then
					if math.random() < 0.05 then
						StructureManager.PlaceOakTree(cf, StructuresFolder)
					elseif math.random() < 0.1 then
						StructureManager.PlaceBush(cf, StructuresFolder)
					end
					tryPlaceRock(0.002)

				elseif b == BiomeType.Plains then
					-- Sparse trees, no clovers/flowers
					if math.random() < 0.002 then -- Very sparse (~1 in 500)
						StructureManager.PlaceOakTree(cf, StructuresFolder)
					elseif math.random() < 0.005 then
						StructureManager.PlaceBush(cf, StructuresFolder)
					end
					tryPlaceRock(0.002)

				elseif b == BiomeType.Beach then
					if math.random() < 0.02 then
						StructureManager.PlacePalmTree(cf, StructuresFolder)
					elseif math.random() < 0.01 then
						StructureManager.PlaceLog(cf, StructuresFolder) -- Driftwood
					end
					tryPlaceRock(0.002)

				elseif b == BiomeType.Mountain then
					if math.random() < 0.05 then
						StructureManager.PlaceRock(cf, StructuresFolder)
					end
				end
			end
		end
	end

	-- CITY STRUCTURE PASS (Guaranteed Placement)
	if townData then
		local centerIdx = CHUNK_SIZE / 2
		local data = heights[centerIdx][centerIdx]
		local h = data.H

		if h > SEA_LEVEL then
			local worldX = (xStart + centerIdx) * VOXEL_SIZE
			local worldZ = (zStart + centerIdx) * VOXEL_SIZE
			local cf = CFrame.new(worldX, h, worldZ)

			local placement = TownManager.GetStructurePlacement(cx, cz, townData)

			if placement == "Road" then
				-- Place road segment
				StructureManager.PlaceRoad(CFrame.new(worldX, h + 0.5, worldZ), StructuresFolder)
			else
				-- Plot
				-- Place 1 building per chunk
				if math.random() > 0.3 then
					local type = pickBuilding(cx, cz)
					print("Placing Building:", type, "at", worldX, worldZ)
					BuildingGenerator.Generate(type, cf, StructuresFolder)
				end
			end
		end
	end
end

local function updateChunks()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local pos = character.HumanoidRootPart.Position
			local pCx = math.floor(pos.X / VOXEL_SIZE / CHUNK_SIZE)
			local pCz = math.floor(pos.Z / VOXEL_SIZE / CHUNK_SIZE)

			for x = -RENDER_DISTANCE, RENDER_DISTANCE do
				for z = -RENDER_DISTANCE, RENDER_DISTANCE do
					generateChunk(pCx + x, pCz + z)
				end
			end
		end
	end
end

task.spawn(function()
	print("Generating Initial Terrain...")
	for x = -3, 3 do
		for z = -3, 3 do
			generateChunk(x, z)
		end
	end
	print("Done")
end)

while true do
	updateChunks()
	task.wait(1)
end
