local TerrainScale = 30
local HeightScale = 25
local GridSize = 4
local MapSize = 64 -- 64x64 grid

local TerrainFolder = workspace:FindFirstChild("TerrainFolder") or Instance.new("Folder")
TerrainFolder.Name = "TerrainFolder"
TerrainFolder.Parent = workspace

-- Clear existing terrain if any (useful for testing when reloading)
TerrainFolder:ClearAllChildren()

print("Generating terrain...")

for x = 0, MapSize - 1 do
	for z = 0, MapSize - 1 do
		local part = Instance.new("Part")
		part.Anchored = true
		part.Size = Vector3.new(GridSize, GridSize * 6, GridSize) -- Tall parts to prevent gaps below
		part.Material = Enum.Material.SmoothPlastic
		
		-- Use math.noise for height generation
		local noiseValue = math.noise(x / TerrainScale, z / TerrainScale, os.time()) -- os.time() for randomness
		local height = noiseValue * HeightScale
		
		part.Position = Vector3.new(x * GridSize, height, z * GridSize)
		
		-- Color map based on height
		if height < -5 then
			part.Color = Color3.fromRGB(24, 126, 204) -- Deep Water
			part.Material = Enum.Material.Plastic
		elseif height < 0 then
			part.Color = Color3.fromRGB(56, 178, 247) -- Shallow Water
		elseif height < 3 then
			part.Color = Color3.fromRGB(237, 214, 128) -- Sand
			part.Material = Enum.Material.Sand
		elseif height < 12 then
			part.Color = Color3.fromRGB(73, 168, 70) -- Grass
			part.Material = Enum.Material.Grass
		elseif height < 18 then
			part.Color = Color3.fromRGB(105, 105, 105) -- Stone
			part.Material = Enum.Material.Slate
		else
			part.Color = Color3.fromRGB(255, 255, 255) -- Snow
			part.Material = Enum.Material.Ice
		end
		
		part.Parent = TerrainFolder
	end
	
	-- Optional: Yield occasionally to prevent freezing the server on large maps
	if x % 10 == 0 then
		task.wait()
	end
end

print("Terrain generation complete!")
